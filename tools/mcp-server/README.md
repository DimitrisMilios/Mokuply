# Mokuply MCP Server 🚀

**Model Context Protocol (MCP)** server for **Mokuply** — automate professional App Store & Google Play mockup screenshots using AI agents like **Antigravity**, **Claude (Desktop & Code)**, Cursor, and Windsurf.

Works seamlessly across **macOS**, **Linux**, and **Windows**.

---

## 🌟 Capabilities

- 📱 **Cross-Platform Simulator & Device Capture**:
  - **macOS**: Automatically captures active **iOS Simulators** (`xcrun simctl`) and **Android Emulators** (`adb`).
  - **Linux & Windows**: Automatically captures connected **Android Emulators / Physical Devices** (`adb.exe` / `adb`).
  - **Universal**: Ingests local image files, directories (`screenshots/`, `fastlane/`), or image URLs.
- 🎨 **Mokuply Project Packaging (`.mokuply`)**:
  - Compiles marketing copy, typography (Google Fonts), themes/gradients, device chassis, and screenshots into a ready-to-load `.mokuply` package.
  - Automatically configures dual-store sync: **iPhone 16 Pro Max (1320×2868)** for App Store, **Samsung Galaxy S26 Ultra (1320×2868)** for Google Play.
- ⚡ **Live Browser Studio Bridge**:
  - Launches Mokuply Web with the AI-generated project loaded in memory via local bridge (`http://127.0.0.1:4004`).
  - Zero cloud uploads — 100% client-side privacy.

---

## 🛠️ MCP Tools Reference

| Tool | Parameters | Description |
| :--- | :--- | :--- |
| `mokuply_list_devices` | *none* | Lists all running iOS Simulators and Android Emulators across macOS, Linux, and Windows. |
| `mokuply_capture_simulator` | `platform` ('auto' \| 'ios' \| 'android'), `deviceId`, `outputDir` | Takes a pixel-perfect screenshot directly from the running simulator/device. |
| `mokuply_find_screenshots` | `workspacePath` | Scans workspace directories (`screenshots/`, `assets/`, `fastlane/`) for existing app screenshots. |
| `mokuply_create_store_project` | `title`, `category`, `theme`, `screens`, `outputFilePath` | Assembles a full multi-screen `.mokuply` package with marketing headlines, subtitles, layouts, and chassis frames. |
| `mokuply_preview_in_browser` | `studioUrl`, `bridgePort` | Starts local bridge and opens Mokuply Studio in your default browser with the generated project. |
| `mokuply_get_themes_and_layouts`| *none* | Returns design references (themes: `midnight`, `titanium`, `sunset`, `emerald`, `ocean`, `minimal_light`, `cyberpunk`, layout modes, chassis styles). |

---

## 💻 Cross-Platform Setup

### Prerequisites
- **Node.js 18+** installed on macOS, Linux, or Windows.
- For iOS capture: macOS with Xcode Command Line Tools (`xcrun simctl`).
- For Android capture: `adb` (Android SDK Platform-Tools) in your system `PATH`.

### Installation
From the root of Mokuply:
```bash
cd tools/mcp-server
npm install
npm run build
```

---

## 🤖 Configuring Your AI Agents

### 1. Claude Desktop

Add this to your Claude Desktop configuration file:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "mokuply": {
      "command": "node",
      "args": ["<PATH_TO_MOKUPLY>/tools/mcp-server/dist/index.js"]
    }
  }
}
```
*(Replace `<PATH_TO_MOKUPLY>` with your absolute path, e.g. `/Users/dmilios/Documents/GitHub/Mokuply` or `C:/Users/.../Mokuply`)*

### 2. Claude Code CLI
```bash
claude mcp add mokuply node <PATH_TO_MOKUPLY>/tools/mcp-server/dist/index.js
```

### 3. Antigravity MCP Setup
In your Antigravity MCP settings or `.gemini/antigravity/mcp/` config:
```json
{
  "mcpServers": {
    "mokuply": {
      "command": "node",
      "args": ["<PATH_TO_MOKUPLY>/tools/mcp-server/dist/index.js"]
    }
  }
}
```

---

## 💬 Example AI Prompts

Try asking Claude or Antigravity:

> *"Check my running simulator, capture the screen, and create a 3-screen App Store & Google Play showcase in Mokuply for a workout tracking app using the Titanium Dark theme. Then open it in my browser so I can review it!"*

> *"Search my project for screenshots and build a 4-screen showcase with punchy marketing headlines using the Midnight Cyber theme. Export the .mokuply project to `./store_mockups.mokuply`."*

> *"What themes and device layout styles does Mokuply support?"*
