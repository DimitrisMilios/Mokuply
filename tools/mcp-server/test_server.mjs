import { createMokuplyPackage } from './dist/generator/packager.js';
import { listAllDevices } from './dist/capture/index.js';
import { THEME_PRESETS } from './dist/generator/themes.js';
import fs from 'node:fs/promises';
import path from 'node:path';

async function runTest() {
  console.log('--- 1. Testing Device Detection ---');
  const devices = await listAllDevices();
  console.log(`Detected devices:`, devices);

  console.log('\n--- 2. Testing Project Generator & ZIP Packager ---');
  const testConfig = {
    title: 'Test Fitness App',
    category: 'Health & Fitness',
    theme: 'midnight',
    screens: [
      {
        titleText: 'Build Serious Muscle',
        subtitleText: 'AI-powered strength tracking and progression',
        layoutMode: 'titleTopDeviceBottom',
        frameStyle: 'realistic',
      },
      {
        titleText: 'Smart Analytics',
        subtitleText: 'Visual volume & hypertrophy trends',
        layoutMode: 'angledLeftHero',
        frameStyle: 'realistic',
      },
    ],
  };

  const outPath = path.resolve('./dist/test_output.mokuply');
  const result = await createMokuplyPackage(testConfig, outPath);

  console.log('Generated Package:');
  console.log('- ZIP Size:', result.zipBuffer.length, 'bytes');
  console.log('- Saved to:', result.outputPath);
  console.log('- Title in JSON:', result.templateJson.title);
  console.log('- Screens count:', (result.templateJson.initialScreenshots || []).length);

  const stat = await fs.stat(outPath);
  console.log('- Verified file on disk:', stat.size, 'bytes');
  await fs.unlink(outPath);

  console.log('\n✅ ALL MCP GENERATOR & PACKAGER TESTS PASSED!');
}

runTest().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
