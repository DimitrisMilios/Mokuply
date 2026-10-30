import { ProjectTemplateConfig, LayoutMode } from '../types/mokuply.js';
export interface LayoutPresetDefaults {
    deviceScale: number;
    deviceOffsetX: number;
    deviceOffsetY: number;
    deviceRotation: number;
    textOffsetX: number;
    textOffsetY: number;
    subtitleOffsetX: number;
    subtitleOffsetY: number;
    titleSize: number;
    subtitleSize: number;
}
export declare function getLayoutDefaults(mode: LayoutMode): LayoutPresetDefaults;
export declare function buildTemplateJson(config: ProjectTemplateConfig, assetMap: Map<string, string>): Record<string, unknown>;
