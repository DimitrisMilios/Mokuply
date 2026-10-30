#!/usr/bin/env node
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import path from 'node:path';
import { listAllDevices, captureSimulator } from './capture/index.js';
import { findWorkspaceScreenshots } from './capture/desktop.js';
import { createMokuplyPackage } from './generator/packager.js';
import { THEME_PRESETS } from './generator/themes.js';
import { getOrStartBridgeServer, setActiveProject } from './bridge/server.js';
import { openBrowser } from './bridge/browser.js';
const server = new McpServer({
    name: 'mokuply-mcp',
    version: '1.0.0',
});
// Tool: List simulators and emulators
server.tool('mokuply_list_devices', 'Lists currently running or booted mobile simulators & emulators (iOS on macOS, Android on macOS/Linux/Windows).', {}, async () => {
    try {
        const devices = await listAllDevices();
        if (devices.length === 0) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `No active mobile simulators detected.\nOperating System: ${process.platform}\n\n- macOS: Start an iOS Simulator via Xcode Simulator.app or an Android Emulator.\n- Linux / Windows: Launch an Android Emulator via Android Studio or 'emulator -avd <name>' and verify 'adb devices' detects it.`,
                    },
                ],
            };
        }
        return {
            content: [
                {
                    type: 'text',
                    text: `Detected ${devices.length} running device(s):\n\n` +
                        devices
                            .map((d, i) => `${i + 1}. [${d.platform.toUpperCase()}] ${d.name} (ID: ${d.id}, State: ${d.state})`)
                            .join('\n'),
                },
            ],
        };
    }
    catch (err) {
        const error = err;
        return {
            content: [{ type: 'text', text: `Error checking devices: ${error.message || String(err)}` }],
            isError: true,
        };
    }
});
// Tool: Capture simulator screenshot
server.tool('mokuply_capture_simulator', 'Captures a pixel-perfect, clean screenshot from the currently running iOS Simulator or Android Emulator (cross-platform: macOS, Linux, Windows).', {
    platform: z
        .enum(['auto', 'ios', 'android'])
        .optional()
        .describe("Target platform to capture from: 'auto' (default), 'ios', or 'android'"),
    deviceId: z.string().optional().describe('UDID or device ID. Omit to capture the booted simulator.'),
    outputDir: z
        .string()
        .optional()
        .describe('Directory to save the screenshot. Defaults to a temporary folder or project screenshot dir.'),
}, async ({ platform, deviceId, outputDir }) => {
    try {
        const result = await captureSimulator({ platform, deviceId, outputDir });
        return {
            content: [
                {
                    type: 'text',
                    text: `Successfully captured ${result.platform.toUpperCase()} screenshot!\nDevice: ${result.deviceName}\nSaved to: ${result.filePath}`,
                },
            ],
        };
    }
    catch (err) {
        const error = err;
        return {
            content: [{ type: 'text', text: `Failed to capture screenshot:\n${error.message || String(err)}` }],
            isError: true,
        };
    }
});
// Tool: Find screenshots in project
server.tool('mokuply_find_screenshots', 'Searches project directories (screenshots/, assets/, fastlane/) for existing app screenshots that can be used for mockups.', {
    workspacePath: z.string().optional().describe('Path to project workspace. Defaults to current working directory.'),
}, async ({ workspacePath }) => {
    try {
        const searchDir = workspacePath || process.cwd();
        const files = await findWorkspaceScreenshots(searchDir);
        if (files.length === 0) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `No screenshot files found in common folders under ${searchDir}. You can specify exact image paths or use 'mokuply_capture_simulator'.`,
                    },
                ],
            };
        }
        return {
            content: [
                {
                    type: 'text',
                    text: `Found ${files.length} screenshot image(s):\n\n` + files.map((f, i) => `${i + 1}. ${f}`).join('\n'),
                },
            ],
        };
    }
    catch (err) {
        const error = err;
        return {
            content: [{ type: 'text', text: `Error finding screenshots: ${error.message || String(err)}` }],
            isError: true,
        };
    }
});
// Tool: Create store project package
server.tool('mokuply_create_store_project', 'Generates a complete multi-screen Mokuply project for App Store (iPhone 16 Pro Max) and Google Play (Galaxy S26 Ultra). Packages screenshots, marketing copy, and themes into a portable .mokuply zip archive.', {
    title: z.string().describe("Showcase project title (e.g., 'Workout Tracker Store Assets')"),
    category: z.string().optional().describe('App category (e.g. Productivity, Finance, Lifestyle)'),
    theme: z
        .enum(['midnight', 'titanium', 'sunset', 'emerald', 'ocean', 'minimal_light', 'cyberpunk'])
        .optional()
        .describe("Theme preset: 'midnight' (default), 'titanium', 'sunset', 'emerald', 'ocean', 'minimal_light', 'cyberpunk'"),
    screens: z
        .array(z.object({
        titleText: z.string().describe("Main headline (e.g., 'Track Workouts Instantly')"),
        subtitleText: z.string().optional().describe("Subtitle text (e.g., 'Smart form analysis and real-time logs')"),
        layoutMode: z
            .enum([
            'titleTopDeviceBottom',
            'angledLeftHero',
            'angledRightHero',
            'titleBottomDeviceTop',
            'deviceCentered',
            'fullBleedHero',
        ])
            .optional()
            .describe('Screen layout arrangement'),
        frameStyle: z
            .enum(['realistic', 'minimalOutline', 'none'])
            .optional()
            .describe('Phone chassis style'),
        screenshotPath: z.string().optional().describe('Path to local screenshot image to place in device frame'),
        iosScreenshotPath: z.string().optional().describe('App Store specific screenshot image path'),
        androidScreenshotPath: z.string().optional().describe('Google Play specific screenshot image path'),
        titleFont: z.string().optional().describe("Headline font name, e.g. 'Outfit', 'Inter', 'Poppins'"),
        subtitleFont: z.string().optional().describe("Subtitle font name, e.g. 'Inter'"),
        textColor: z.string().optional().describe("Headline text hex color, e.g. '#FFFFFF'"),
        subtitleColor: z.string().optional().describe("Subtitle text hex color, e.g. '#94A3B8'"),
    }))
        .describe('List of screens to generate for the store showcase'),
    outputFilePath: z
        .string()
        .optional()
        .describe("Destination path for .mokuply zip package (e.g. './showcase.mokuply' or './screenshots/store_set.zip')"),
}, async ({ title, category, theme, screens, outputFilePath }) => {
    try {
        const preset = THEME_PRESETS[theme ?? 'midnight'] || THEME_PRESETS.midnight;
        const templateConfig = {
            title,
            category: category ?? 'App Showcase',
            description: `Designed with Mokuply AI for App Store & Google Play`,
            previewGradient: preset.gradient,
            platform: 'appStore',
            screens: screens.map(s => ({
                ...s,
                titleFont: s.titleFont ?? preset.defaultTitleFont,
                subtitleFont: s.subtitleFont ?? preset.defaultSubtitleFont,
                textColor: s.textColor ?? preset.textColor,
                subtitleColor: s.subtitleColor ?? preset.subtitleColor,
                customGradientColors: preset.gradient,
            })),
        };
        const defaultOut = outputFilePath || path.resolve(process.cwd(), `${title.toLowerCase().replace(/\s+/g, '_')}.mokuply`);
        const pkg = await createMokuplyPackage(templateConfig, defaultOut);
        // Save to active in-memory session for bridge
        setActiveProject(pkg);
        return {
            content: [
                {
                    type: 'text',
                    text: `Successfully created Mokuply Store Showcase!\n` +
                        `- Project: "${title}"\n` +
                        `- Screens: ${screens.length}\n` +
                        `- Theme: ${preset.name}\n` +
                        `- Packaged Assets: ${pkg.assetCount} screenshot(s)\n` +
                        `- Output File: ${pkg.outputPath}\n\n` +
                        `Both Apple App Store (1320×2868) and Google Play Store formats are configured in this unified project.\n` +
                        `Call 'mokuply_preview_in_browser' to open Mokuply Studio and preview/export!`,
                },
            ],
        };
    }
    catch (err) {
        const error = err;
        return {
            content: [{ type: 'text', text: `Failed to create store project: ${error.message || String(err)}` }],
            isError: true,
        };
    }
});
// Tool: Preview and live bridge in browser
server.tool('mokuply_preview_in_browser', 'Opens Mokuply Web studio in your default browser (macOS, Linux, Windows) with the generated project loaded via local bridge.', {
    studioUrl: z
        .string()
        .optional()
        .describe("URL to Mokuply Web app. Defaults to 'http://localhost:8080' or hosted instance."),
    bridgePort: z.number().optional().describe('Port for local MCP HTTP bridge. Defaults to 4004.'),
}, async ({ studioUrl, bridgePort }) => {
    try {
        const port = bridgePort ?? 4004;
        const bridge = await getOrStartBridgeServer(port);
        const active = bridge.getActiveProject();
        if (!active) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `Bridge server is running on ${bridge.url}, but no project has been generated yet. Please run 'mokuply_create_store_project' first!`,
                    },
                ],
            };
        }
        const baseStudio = studioUrl ?? 'http://localhost:8080';
        const fullUrl = `${baseStudio}?bridge=${encodeURIComponent(bridge.url + '/session.mokuply')}`;
        await openBrowser(fullUrl);
        return {
            content: [
                {
                    type: 'text',
                    text: `Mokuply Studio opened in browser!\n- Studio URL: ${fullUrl}\n- Local MCP Bridge: ${bridge.url}\n\nYou can now preview both Apple and Google Play rows, adjust typography, fine-tune device angles, and export the final 1320×2868 bundles!`,
                },
            ],
        };
    }
    catch (err) {
        const error = err;
        return {
            content: [{ type: 'text', text: `Error launching preview: ${error.message || String(err)}` }],
            isError: true,
        };
    }
});
// Tool: Themes and layouts catalog
server.tool('mokuply_get_themes_and_layouts', 'Returns design reference for themes, layout arrangements, and device styles supported by Mokuply.', {}, async () => {
    const themeList = Object.entries(THEME_PRESETS)
        .map(([key, t]) => `- **${key}** (${t.name}): ${t.description} (Gradient: ${t.gradient.join(' -> ')})`)
        .join('\n');
    const text = `# Mokuply Design System Reference

## Theme Presets
${themeList}

## Layout Modes
- **titleTopDeviceBottom**: Classic app store layout with large headline and subtitle above a bottom-anchored device frame.
- **angledLeftHero**: Dynamic 3D perspective with device tilted -16 degrees to the left.
- **angledRightHero**: Dynamic 3D perspective with device tilted +16 degrees to the right.
- **titleBottomDeviceTop**: Modern layout with device in upper viewport and marketing copy below.
- **deviceCentered**: Minimalist spotlight focused on the device frame.
- **fullBleedHero**: Large zoomed device frame showing detail.

## Device Frame Styles
- **realistic**: Dual-store chassis (iPhone 16 Pro Max for App Store, Samsung Galaxy S26 Ultra for Google Play).
- **minimalOutline**: Universal sleek dark border.
- **none**: Border-less raw screenshot with soft clay drop shadow.

## Coordinates & Specs
- Unified coordinate space: 1320 × 2868 px.
- Apple App Store export: 1320 × 2868 px lossless PNG.
- Google Play export: 1320 × 2868 px lossless PNG.
`;
    return {
        content: [{ type: 'text', text }],
    };
});
// Start server on standard I/O
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch(err => {
    console.error('Fatal MCP server error:', err);
    process.exit(1);
});
//# sourceMappingURL=index.js.map