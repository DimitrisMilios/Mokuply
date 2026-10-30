import { ProjectTemplateConfig } from '../types/mokuply.js';
export interface PackageResult {
    zipBuffer: Buffer;
    templateJson: Record<string, unknown>;
    outputPath?: string;
    assetCount: number;
}
export declare function createMokuplyPackage(config: ProjectTemplateConfig, outputFilePath?: string): Promise<PackageResult>;
