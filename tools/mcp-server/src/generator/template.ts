import {
  ScreenConfig,
  ProjectTemplateConfig,
  LayoutMode,
  CanvasDeviceItemConfig,
  TargetPlatformType,
} from '../types/mokuply.js';
import { parseColor, THEME_PRESETS, hexToArgb } from './themes.js';

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

export function getLayoutDefaults(mode: LayoutMode): LayoutPresetDefaults {
  switch (mode) {
    case 'angledLeftHero':
      return {
        deviceScale: 0.95,
        deviceOffsetX: -100.0,
        deviceOffsetY: 260.0,
        deviceRotation: -16.0,
        textOffsetX: -80.0,
        textOffsetY: -60.0,
        subtitleOffsetX: -80.0,
        subtitleOffsetY: -60.0,
        titleSize: 104.0,
        subtitleSize: 46.0,
      };
    case 'angledRightHero':
      return {
        deviceScale: 0.95,
        deviceOffsetX: 100.0,
        deviceOffsetY: 260.0,
        deviceRotation: 16.0,
        textOffsetX: 80.0,
        textOffsetY: -60.0,
        subtitleOffsetX: 80.0,
        subtitleOffsetY: -60.0,
        titleSize: 104.0,
        subtitleSize: 46.0,
      };
    case 'titleBottomDeviceTop':
      return {
        deviceScale: 0.94,
        deviceOffsetX: 0.0,
        deviceOffsetY: -360.0,
        deviceRotation: 0.0,
        textOffsetX: 0.0,
        textOffsetY: 1020.0,
        subtitleOffsetX: 0.0,
        subtitleOffsetY: 1020.0,
        titleSize: 96.0,
        subtitleSize: 42.0,
      };
    case 'deviceCentered':
      return {
        deviceScale: 1.05,
        deviceOffsetX: 0.0,
        deviceOffsetY: 100.0,
        deviceRotation: 0.0,
        textOffsetX: 0.0,
        textOffsetY: -900.0,
        subtitleOffsetX: 0.0,
        subtitleOffsetY: -900.0,
        titleSize: 88.0,
        subtitleSize: 40.0,
      };
    case 'fullBleedHero':
      return {
        deviceScale: 1.25,
        deviceOffsetX: 0.0,
        deviceOffsetY: 380.0,
        deviceRotation: 0.0,
        textOffsetX: 0.0,
        textOffsetY: -1000.0,
        subtitleOffsetX: 0.0,
        subtitleOffsetY: -1000.0,
        titleSize: 96.0,
        subtitleSize: 42.0,
      };
    case 'titleTopDeviceBottom':
    default:
      return {
        deviceScale: 0.92,
        deviceOffsetX: 0.0,
        deviceOffsetY: 320.0,
        deviceRotation: 0.0,
        textOffsetX: 0.0,
        textOffsetY: 0.0,
        subtitleOffsetX: 0.0,
        subtitleOffsetY: 0.0,
        titleSize: 96.0,
        subtitleSize: 42.0,
      };
  }
}

export function buildTemplateJson(
  config: ProjectTemplateConfig,
  assetMap: Map<string, string> // maps file path or asset key to "images/1.png"
): Record<string, unknown> {
  const theme = THEME_PRESETS.midnight;
  const platform: TargetPlatformType = config.platform ?? 'appStore';

  const previewGradient = config.previewGradient
    ? config.previewGradient.map(c => parseColor(c))
    : theme.gradient.map(hex => hexToArgb(hex));

  const screens = config.screens.map((screen, index) => {
    const layout = screen.layoutMode ?? 'titleTopDeviceBottom';
    const defaults = getLayoutDefaults(layout);

    const gradientColors = screen.customGradientColors
      ? screen.customGradientColors.map(c => parseColor(c))
      : previewGradient;

    // Devices config
    let devices = screen.devices;
    if (!devices || devices.length === 0) {
      // Create primary device
      const screenshotAsset = screen.screenshotPath ? assetMap.get(screen.screenshotPath) : undefined;
      const iosAsset = screen.iosScreenshotPath ? assetMap.get(screen.iosScreenshotPath) : screenshotAsset;
      const androidAsset = screen.androidScreenshotPath ? assetMap.get(screen.androidScreenshotPath) : screenshotAsset;

      devices = [
        {
          id: `dev_${index + 1}_primary`,
          frameStyle: screen.frameStyle ?? 'realistic',
          scale: screen.deviceScale ?? defaults.deviceScale,
          offsetX: screen.deviceOffsetX ?? defaults.deviceOffsetX,
          offsetY: screen.deviceOffsetY ?? defaults.deviceOffsetY,
          rotation: screen.deviceRotation ?? defaults.deviceRotation,
          hasShadow: screen.hasShadow ?? true,
          iosScreenshot: iosAsset,
          androidScreenshot: androidAsset,
        },
      ];
    } else {
      devices = devices.map((d, dIdx) => ({
        ...d,
        id: d.id ?? `dev_${index + 1}_${dIdx + 1}`,
        iosScreenshot: d.iosScreenshot ? assetMap.get(d.iosScreenshot) ?? d.iosScreenshot : undefined,
        androidScreenshot: d.androidScreenshot ? assetMap.get(d.androidScreenshot) ?? d.androidScreenshot : undefined,
      }));
    }

    return {
      platform,
      name: screen.name || `Screen ${index + 1}`,
      layoutMode: layout,
      frameStyle: screen.frameStyle ?? 'realistic',
      titleText: screen.titleText,
      subtitleText: screen.subtitleText ?? '',
      titleFont: screen.titleFont ?? 'Outfit',
      subtitleFont: screen.subtitleFont ?? 'Inter',
      titleSize: screen.titleSize ?? defaults.titleSize,
      subtitleSize: screen.subtitleSize ?? defaults.subtitleSize,
      titleWeightIndex: screen.titleWeightIndex ?? 6, // FontWeight.w700
      subtitleWeightIndex: screen.subtitleWeightIndex ?? 4, // FontWeight.w500
      textColor: parseColor(screen.textColor, '#FFFFFF'),
      subtitleColor: parseColor(screen.subtitleColor, '#94A3B8'),
      titleAlignment: screen.titleAlignment ?? 'center',
      subtitleAlignment: screen.subtitleAlignment ?? 'center',
      selectedGradientIndex: screen.selectedGradientIndex ?? 0,
      customBackgroundColor: screen.customBackgroundColor ? parseColor(screen.customBackgroundColor) : null,
      customGradientColors: gradientColors,
      deviceScale: screen.deviceScale ?? defaults.deviceScale,
      deviceOffsetX: screen.deviceOffsetX ?? defaults.deviceOffsetX,
      deviceOffsetY: screen.deviceOffsetY ?? defaults.deviceOffsetY,
      deviceRotation: screen.deviceRotation ?? defaults.deviceRotation,
      hasShadow: screen.hasShadow ?? true,
      textOffsetX: screen.textOffsetX ?? defaults.textOffsetX,
      textOffsetY: screen.textOffsetY ?? defaults.textOffsetY,
      subtitleOffsetX: screen.subtitleOffsetX ?? defaults.subtitleOffsetX,
      subtitleOffsetY: screen.subtitleOffsetY ?? defaults.subtitleOffsetY,
      devices,
      customImageItems: [],
      customTextItems: [],
      textUnit: 'px',
    };
  });

  return {
    id: config.id ?? `mokuply_${Date.now()}`,
    title: config.title,
    category: config.category ?? 'App Store Showcase',
    description: config.description ?? 'AI-generated showcase screenshots with Mokuply',
    previewGradient,
    platform,
    initialScreenshots: screens,
  };
}
