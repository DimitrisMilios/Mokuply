/**
 * Theme & Color Utilities for Mokuply
 */

export function hexToArgb(hex: string): number {
  let clean = hex.replace('#', '').trim();
  if (clean.length === 3) {
    clean = clean.split('').map(c => c + c).join('');
  }
  if (clean.length === 6) {
    clean = 'FF' + clean;
  }
  return parseInt(clean, 16);
}

export function parseColor(color: string | number | undefined, defaultHex = '#FFFFFF'): number {
  if (color === undefined || color === null) return hexToArgb(defaultHex);
  if (typeof color === 'number') return color;
  return hexToArgb(color);
}

export interface ThemePreset {
  name: string;
  description: string;
  gradient: string[];
  textColor: string;
  subtitleColor: string;
  defaultTitleFont: string;
  defaultSubtitleFont: string;
}

export const THEME_PRESETS: Record<string, ThemePreset> = {
  midnight: {
    name: 'Midnight Cyber',
    description: 'Deep navy-indigo gradient, ultra modern tech and AI apps',
    gradient: ['#0B0F19', '#1E293B', '#0F172A'],
    textColor: '#FFFFFF',
    subtitleColor: '#94A3B8',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  titanium: {
    name: 'Titanium Dark',
    description: 'Apple-inspired dark titanium studio finish',
    gradient: ['#18181B', '#27272A', '#121214'],
    textColor: '#F4F4F5',
    subtitleColor: '#A1A1AA',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  sunset: {
    name: 'Sunset Glow',
    description: 'Warm purple-to-coral sunset gradient, great for social & lifestyle',
    gradient: ['#4C1D95', '#7C3AED', '#DB2777'],
    textColor: '#FFFFFF',
    subtitleColor: '#FBCFE8',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  emerald: {
    name: 'Forest Emerald',
    description: 'Fintech and wellness green gradient',
    gradient: ['#064E3B', '#047857', '#059669'],
    textColor: '#FFFFFF',
    subtitleColor: '#A7F3D0',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  ocean: {
    name: 'Ocean Gradient',
    description: 'Vibrant azure blue gradient, perfect for productivity & utility',
    gradient: ['#1E3A8A', '#2563EB', '#38BDF8'],
    textColor: '#FFFFFF',
    subtitleColor: '#E0F2FE',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  minimal_light: {
    name: 'Clean Studio Light',
    description: 'Warm soft paper clay aesthetic with high-contrast slate text',
    gradient: ['#F8FAFC', '#F1F5F9', '#E2E8F0'],
    textColor: '#0F172A',
    subtitleColor: '#475569',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
  cyberpunk: {
    name: 'Neon Violet',
    description: 'Punchy cyberpunk neon violet and fuchsia',
    gradient: ['#311042', '#581C87', '#9333EA'],
    textColor: '#FFFFFF',
    subtitleColor: '#E9D5FF',
    defaultTitleFont: 'Outfit',
    defaultSubtitleFont: 'Inter',
  },
};
