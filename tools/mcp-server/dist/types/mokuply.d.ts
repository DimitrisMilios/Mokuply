/**
 * Mokuply Data Types
 * Matches Dart definitions in `lib/models/` and `lib/core/constants/store_specs.dart`
 */
export type TargetPlatformType = 'appStore' | 'googlePlay';
export type LayoutMode = 'angledLeftHero' | 'angledRightHero' | 'titleTopDeviceBottom' | 'titleBottomDeviceTop' | 'deviceCentered' | 'fullBleedHero';
export type DeviceFrameStyle = 'realistic' | 'minimalOutline' | 'none';
export type TextAlign = 'left' | 'center' | 'right' | 'justify';
export interface CanvasDeviceItemConfig {
    id?: string;
    frameStyle?: DeviceFrameStyle;
    scale?: number;
    offsetX?: number;
    offsetY?: number;
    rotation?: number;
    hasShadow?: boolean;
    iosScreenshot?: string;
    androidScreenshot?: string;
}
export interface ScreenConfig {
    name?: string;
    platform?: TargetPlatformType;
    layoutMode?: LayoutMode;
    frameStyle?: DeviceFrameStyle;
    titleText: string;
    subtitleText?: string;
    titleFont?: string;
    subtitleFont?: string;
    titleSize?: number;
    subtitleSize?: number;
    titleWeightIndex?: number;
    subtitleWeightIndex?: number;
    textColor?: string | number;
    subtitleColor?: string | number;
    titleAlignment?: TextAlign;
    subtitleAlignment?: TextAlign;
    selectedGradientIndex?: number;
    customBackgroundColor?: string | number;
    customGradientColors?: (string | number)[];
    deviceScale?: number;
    deviceOffsetX?: number;
    deviceOffsetY?: number;
    deviceRotation?: number;
    hasShadow?: boolean;
    textOffsetX?: number;
    textOffsetY?: number;
    subtitleOffsetX?: number;
    subtitleOffsetY?: number;
    devices?: CanvasDeviceItemConfig[];
    /** Screenshot file path or buffer used to populate devices */
    screenshotPath?: string;
    iosScreenshotPath?: string;
    androidScreenshotPath?: string;
}
export interface ProjectTemplateConfig {
    id?: string;
    title: string;
    category?: string;
    description?: string;
    previewGradient?: (string | number)[];
    platform?: TargetPlatformType;
    screens: ScreenConfig[];
}
export interface CapturedDevice {
    id: string;
    name: string;
    platform: 'ios' | 'android' | 'desktop';
    state: 'booted' | 'device' | 'active';
    details?: string;
}
