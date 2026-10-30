/**
 * Theme & Color Utilities for Mokuply
 */
export declare function hexToArgb(hex: string): number;
export declare function parseColor(color: string | number | undefined, defaultHex?: string): number;
export interface ThemePreset {
    name: string;
    description: string;
    gradient: string[];
    textColor: string;
    subtitleColor: string;
    defaultTitleFont: string;
    defaultSubtitleFont: string;
}
export declare const THEME_PRESETS: Record<string, ThemePreset>;
