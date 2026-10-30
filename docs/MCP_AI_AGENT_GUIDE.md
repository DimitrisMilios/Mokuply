# Mokuply MCP & AI Agent Guide 🤖

This guide explains how to connect and automate **Mokuply** using the **Model Context Protocol (MCP)** with AI agents including **Antigravity**, **Claude (Desktop & Code)**, Cursor, and Windsurf.

Supported across **macOS**, **Linux**, and **Windows**.

---

## Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Supported Platforms & Capabilities](#2-supported-platforms--capabilities)
3. [Setup & Installation](#3-setup--installation)
   - [Claude Desktop](#claude-desktop)
   - [Claude Code CLI](#claude-code-cli)
   - [Antigravity](#antigravity)
   - [Cursor / Windsurf](#cursor--windsurf)
4. [MCP Tools Reference](#4-mcp-tools-reference)
5. [End-to-End Workflows & Prompt Examples](#5-end-to-end-workflows--prompt-examples)
6. [Design System & Styling Options](#6-design-system--styling-options)
7. [Local Bridge & Web App Sync Protocol](#7-local-bridge--web-app-sync-protocol)
8. [Troubleshooting & FAQ](#8-troubleshooting--faq)

---

## 1. Overview & Architecture

The **Mokuply MCP Server** (`tools/mcp-server`) turns Mokuply into an AI-controllable screenshot studio. Instead of manually taking screenshots, resizing them, choosing fonts, and positioning phones, you can instruct your AI assistant in natural language to:
- Detect and screenshot running iOS Simulators and Android Emulators.
- Compose compelling marketing copy and layouts for the Apple App Store and Google Play Store.
- Package everything into a self-contained `.mokuply` template archive.
- Pop open the Mokuply web app in your browser with your screens already populated for visual review and high-res export.

```
┌───────────────────────────────────────────────┐
│              AI Assistant / Agent             │
│    (Antigravity · Claude Desktop · Cursor)    │
└───────────────────────┬───────────────────────┘
                        │ Model Context Protocol (stdio)
                        ▼
┌───────────────────────────────────────────────┐
│              Mokuply MCP Server               │
│               tools/mcp-server                │
├───────────────────────┬───────────────────────┤
│  Device Capture       │  Template Generator   │
│  - xcrun simctl (Mac) │  - 1320×2868 Design   │
│  - adb (All OSes)     │  - Dual Store Sync    │
│  - Local file search  │  - .mokuply packager  │
└───────────────────────┼───────────────────────┘
                        │
                        ▼ Local Bridge (http://127.0.0.1:4004)
┌───────────────────────────────────────────────┐
│               Mokuply Web Studio              │
│       Browser Canvas (100% Client-Side)       │
└───────────────────────────────────────────────┘
```

---

## 2. Supported Platforms & Capabilities

| Operating System | Mobile Capture Method | Desktop Image Support | Browser Launch |
| :--- | :--- | :--- | :--- |
| **macOS** | • **iOS Simulator** (`xcrun simctl`)<br>• **Android Emulator** (`adb`) | PNG, JPEG, WebP files | `open <url>` |
| **Linux** | • **Android Emulator** (`adb`)<br>• Physical Android devices | PNG, JPEG, WebP files | `xdg-open <url>` |
| **Windows** | • **Android Emulator** (`adb.exe`)<br>• Physical Android devices | PNG, JPEG, WebP files | `cmd.exe /c start <url>` |

---

## 3. Setup & Installation

### Step 1: Build the MCP Server

Ensure you have **Node.js 18+** installed. From the root of the Mokuply repository:

```bash
cd tools/mcp-server
npm install
npm run build
```

This compiles the TypeScript source into `tools/mcp-server/dist/index.js`.

---

### Step 2: Configure Your Agent

#### Claude Desktop

Locate or create your `claude_desktop_config.json`:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Add the `mokuply` server entry:

```json
{
  "mcpServers": {
    "mokuply": {
      "command": "node",
      "args": [
        "<ABSOLUTE_PATH_TO_MOKUPLY>/tools/mcp-server/dist/index.js"
      ]
    }
  }
}
```

*(Replace `<ABSOLUTE_PATH_TO_MOKUPLY>` with the absolute path on your system, e.g. `/path/to/Mokuply` on macOS/Linux or `C:/path/to/Mokuply` on Windows).*

Restart Claude Desktop. You will see the hammer icon with `mokuply` tools available!

---

#### Claude Code CLI

Run this command in your terminal:

```bash
claude mcp add mokuply node <ABSOLUTE_PATH_TO_MOKUPLY>/tools/mcp-server/dist/index.js
```

---

#### Antigravity

In your Antigravity workspace settings or `.gemini/antigravity/mcp/` configuration:

```json
{
  "mcpServers": {
    "mokuply": {
      "command": "node",
      "args": ["tools/mcp-server/dist/index.js"]
    }
  }
}
```

---

## 4. MCP Tools Reference

### 1. `mokuply_list_devices`
Discovers running virtual devices across all platforms.
- **Returns**: List of active iOS Simulators (with UDIDs) and Android Emulators/devices.

### 2. `mokuply_capture_simulator`
Captures a high-resolution, unclipped screenshot directly from the running device.
- **Parameters**:
  - `platform` *(optional)*: `'auto'` (default), `'ios'`, or `'android'`.
  - `deviceId` *(optional)*: Specific device UDID or serial. Omit to target the booted device.
  - `outputDir` *(optional)*: Directory to save the captured PNG.
- **Returns**: Path to the saved image file.

### 3. `mokuply_find_screenshots`
Auto-discovers existing screenshot images in common project folders (`screenshots/`, `assets/`, `fastlane/screenshots/`).
- **Parameters**:
  - `workspacePath` *(optional)*: Root folder to search. Defaults to current directory.

### 4. `mokuply_create_store_project`
Compiles screenshots and copy into a dual-store Mokuply project.
- **Parameters**:
  - `title` *(required)*: Project title.
  - `category` *(optional)*: Store category (e.g. *Productivity*, *Health & Fitness*).
  - `theme` *(optional)*: Gradient preset (`midnight`, `titanium`, `sunset`, `emerald`, `ocean`, `minimal_light`, `cyberpunk`).
  - `screens` *(required)*: Array of screen definitions:
    - `titleText`: Main marketing headline.
    - `subtitleText`: Subtitle / description.
    - `layoutMode`: Screen arrangement (`titleTopDeviceBottom`, `angledLeftHero`, `angledRightHero`, `titleBottomDeviceTop`, `deviceCentered`, `fullBleedHero`).
    - `frameStyle`: Chassis frame (`realistic`, `minimalOutline`, `none`).
    - `screenshotPath`: Path to screenshot image.
    - `titleFont`: Google Font name (e.g. `Outfit`, `Inter`, `Poppins`, `Montserrat`).
    - `textColor` / `subtitleColor`: Hex colors.
  - `outputFilePath` *(optional)*: Destination for `.mokuply` ZIP package.

### 5. `mokuply_preview_in_browser`
Spins up the local in-memory bridge and launches Mokuply Web in your default browser.
- **Parameters**:
  - `studioUrl` *(optional)*: Base URL for Mokuply (defaults to `http://localhost:8080`).
  - `bridgePort` *(optional)*: Local bridge port (defaults to `4004`).

### 6. `mokuply_get_themes_and_layouts`
Returns design reference documentation for the LLM to choose harmonious color palettes and layouts.

---

## 5. End-to-End Workflows & Prompt Examples

### Workflow 1: Capture from Simulator & Build Full Showcase
> **User Prompt**:
> *"Take a screenshot from my booted iOS simulator, generate a 3-screen App Store showcase for my habit tracker app with the Midnight Cyber theme, and open it in Mokuply so I can preview it."*

**What the AI does:**
1. Calls `mokuply_list_devices` → finds `iPhone 16 Pro Max (Booted)`.
2. Calls `mokuply_capture_simulator` → saves clean screenshot.
3. Calls `mokuply_create_store_project` with:
   - Screen 1: *"Build Daily Habits"*, `titleTopDeviceBottom` layout.
   - Screen 2: *"Track Your Progress"*, `angledLeftHero` layout.
   - Screen 3: *"Never Break The Chain"*, `titleTopDeviceBottom` layout.
4. Calls `mokuply_preview_in_browser` → opens `http://localhost:8080?bridge=http://127.0.0.1:4004/session.mokuply`.

---

### Workflow 2: Ingest Fastlane Screenshots
> **User Prompt**:
> *"Search my `screenshots/` directory for my app's recent screens, create a 4-screen Google Play & App Store set using the Titanium Dark theme, and save the .mokuply file to `./store_set.mokuply`."*

**What the AI does:**
1. Calls `mokuply_find_screenshots`.
2. Matches screenshots to screens.
3. Generates the dual-store package with identical bounding boxes for iPhone 16 Pro Max & Samsung Galaxy S26 Ultra.

---

## 6. Design System & Styling Options

### Built-in Themes

| Theme ID | Name | Aesthetics | Best For |
| :--- | :--- | :--- | :--- |
| `midnight` | Midnight Cyber | Deep navy to indigo slate with crisp white typography | AI apps, developer tools, fintech |
| `titanium` | Titanium Dark | Apple-inspired dark titanium studio finish | Premium utility, camera, audio apps |
| `sunset` | Sunset Glow | Warm violet to coral magenta | Social, dating, media, lifestyle |
| `emerald` | Forest Emerald | Deep forest to vibrant emerald mint | Health, finance, investing, ecology |
| `ocean` | Ocean Gradient | Deep azure to sky blue | Productivity, weather, travel |
| `minimal_light`| Clean Studio Light | Soft paper clay tones with dark slate text | SaaS, enterprise, reading apps |
| `cyberpunk` | Neon Violet | Electric violet to vivid purple | Gaming, crypto, creator apps |

---

## 7. Local Bridge & Web App Sync Protocol

Mokuply keeps your data 100% private. The MCP server does **not** upload your unreleased app screenshots or assets to any external cloud:

1. When a project is generated, the MCP server keeps it in memory and can optionally save a local `.mokuply` ZIP file.
2. The local bridge server runs strictly on `127.0.0.1:4004`.
3. When Mokuply Web opens with `?bridge=http://127.0.0.1:4004/session.mokuply`, the browser fetches the package directly over loopback memory.
4. Mokuply's `BridgeFetcher` decodes the ZIP into CanvasKit memory and opens the editor immediately.

---

## 8. Troubleshooting & FAQ

#### Q: "No active iOS Simulator detected" on macOS
- Verify that Xcode's Simulator is running: `open -a Simulator`.
- Check in terminal: `xcrun simctl list devices | grep Booted`.

#### Q: "adb not found" on Windows / Linux / macOS
- Ensure Android SDK platform-tools is installed and added to your system `PATH`.
- Run `adb devices` in terminal or Command Prompt to confirm.

#### Q: Can I run this offline?
- **Yes.** Both Mokuply and the MCP bridge run entirely on local loopback (`127.0.0.1`). No active internet connection is required once packages are installed.
