import JSZip from 'jszip';
import fs from 'node:fs/promises';
import path from 'node:path';
import { ProjectTemplateConfig } from '../types/mokuply.js';
import { buildTemplateJson } from './template.js';

export interface PackageResult {
  zipBuffer: Buffer;
  templateJson: Record<string, unknown>;
  outputPath?: string;
  assetCount: number;
}

export async function createMokuplyPackage(
  config: ProjectTemplateConfig,
  outputFilePath?: string
): Promise<PackageResult> {
  const zip = new JSZip();
  const assetMap = new Map<string, string>();
  let assetCounter = 1;

  // Gather all unique image paths referenced in screens
  const imagePathsToLoad = new Set<string>();

  for (const screen of config.screens) {
    if (screen.screenshotPath) imagePathsToLoad.add(screen.screenshotPath);
    if (screen.iosScreenshotPath) imagePathsToLoad.add(screen.iosScreenshotPath);
    if (screen.androidScreenshotPath) imagePathsToLoad.add(screen.androidScreenshotPath);

    if (screen.devices) {
      for (const dev of screen.devices) {
        if (dev.iosScreenshot && !dev.iosScreenshot.startsWith('images/')) {
          imagePathsToLoad.add(dev.iosScreenshot);
        }
        if (dev.androidScreenshot && !dev.androidScreenshot.startsWith('images/')) {
          imagePathsToLoad.add(dev.androidScreenshot);
        }
      }
    }
  }

  // Load images and add them to zip images/ folder
  for (const imgPath of imagePathsToLoad) {
    try {
      const resolvedPath = path.resolve(imgPath);
      const fileBuffer = await fs.readFile(resolvedPath);
      const ext = path.extname(imgPath).toLowerCase() || '.png';
      const archiveName = `images/${assetCounter}${ext}`;
      zip.file(archiveName, fileBuffer);
      assetMap.set(imgPath, archiveName);
      assetMap.set(resolvedPath, archiveName);
      assetCounter++;
    } catch (err) {
      console.error(`Warning: Could not read image at "${imgPath}":`, err);
    }
  }

  // Build the template.json referencing the archived assets
  const templateJson = buildTemplateJson(config, assetMap);
  zip.file('template.json', JSON.stringify(templateJson, null, 2));

  // Generate ZIP Buffer
  const zipBuffer = await zip.generateAsync({
    type: 'nodebuffer',
    compression: 'DEFLATE',
    compressionOptions: { level: 6 },
  });

  if (outputFilePath) {
    const resolvedOut = path.resolve(outputFilePath);
    await fs.mkdir(path.dirname(resolvedOut), { recursive: true });
    await fs.writeFile(resolvedOut, zipBuffer);
    return {
      zipBuffer,
      templateJson,
      outputPath: resolvedOut,
      assetCount: assetMap.size,
    };
  }

  return {
    zipBuffer,
    templateJson,
    assetCount: assetMap.size,
  };
}
