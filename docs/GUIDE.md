# Mokuply · Complete User Guide & Feature Manual

Welcome to the official documentation for **Mokuply**, the 100% client-side, open-source mobile mockup studio for the Apple App Store and Google Play Store.

This comprehensive guide covers every tool, layout mode, design system detail, keyboard shortcut, and workflow trick in Mokuply.

---

## Table of Contents

1. [Core Philosophy & Architecture](#1-core-philosophy--architecture)
2. [Getting Started](#2-getting-started)
3. [The Mokuply Interface](#3-the-mokuply-interface)
4. [The Dual-Store Workflow & Unified Canvas](#4-the-dual-store-workflow--unified-canvas)
5. [Managing Screens & The Strip](#5-managing-screens--the-strip)
6. [Canvas Elements & Manipulation](#6-canvas-elements--manipulation)
   - [Phone Frames](#phone-frames)
   - [Typography & Google Fonts](#typography--google-fonts)
   - [Custom Image Overlays](#custom-image-overlays)
   - [Backdrops & Gradients](#backdrops--gradients)
   - [Direct Canvas Handles & Magnetic Snapping](#direct-canvas-handles--magnetic-snapping)
7. [Template System & Portability](#7-template-system--portability)
   - [Saving to Browser Gallery](#saving-to-browser-gallery)
   - [Exporting & Importing `.mokuply` Files](#exporting--importing-mokuply-files)
   - [Contributor Dart Code Generator](#contributor-dart-code-generator)
8. [Draft Autosave & Session Recovery](#8-draft-autosave--session-recovery)
9. [Export Pipeline & Technical Specifications](#9-export-pipeline--technical-specifications)
10. [App Store Optimization (ASO) Playbook](#10-app-store-optimization-aso-playbook)
11. [Complete Keyboard Shortcuts](#11-complete-keyboard-shortcuts)
12. [Troubleshooting & FAQ](#12-troubleshooting--faq)
13. [AI Agent & MCP Automation (Claude & Antigravity)](#13-ai-agent--mcp-automation-claude--antigravity)

---

## 1. Core Philosophy & Architecture

### 100% In-Browser & Private
Unlike traditional design web-apps that upload your mockups, unreleased app screenshots, and confidential graphics to cloud servers, **Mokuply processes everything locally inside your browser memory**.
- **No telemetry or tracker scripts**: No third-party analytics watching your canvas.
- **Zero remote uploads**: Screenshot bitmaps, image overlays, and project templates stay within your machine's sandbox.
- **CanvasKit Engine**: Powered by Flutter's WebAssembly CanvasKit backend, providing hardware-accelerated 60 FPS graphics and desktop-grade text rendering.

### The "Design Once, Publish Everywhere" Model
Publishing to both stores traditionally requires opening two design files, manually resizing frames, and coping with mismatched dimensions. Mokuply solves this through a **Unified Design Space of 1320×2868**:
- You compose typography, device tilts, and badges on one master canvas.
- When switching between iOS and Android, Mokuply keeps the footprint identical while swapping the hardware chassis (iPhone 16 Pro Max Dynamic Island ↔ Galaxy S26 Ultra hole-punch).

---

## 2. Getting Started

### The Home Portal
When opening Mokuply, you arrive at the home view:
- **Hero Area**: Instant access to jump into the editor or browse templates.
- **Saved Draft Banner**: If you previously worked on a project, Mokuply detects your local draft and displays a quick-resume banner.
- **Starter Template Gallery**: Pre-crafted, high-converting design sets categorized for different app styles (Productivity, SaaS, Clean Minimalist, Dark Neon).
- **Import Button**: Load any `.mokuply` file from your computer.

### Creating Your First Project
1. Choose any template card from the gallery (e.g. *Team Organize* or *SaaS Modern*), or start fresh.
2. The interactive editor workspace loads immediately with pre-configured screens.
3. Replace the placeholder screenshots with your real app screens by clicking any device frame.

---

## 3. The Mokuply Interface

The editor interface is crafted with a soft, tactile **Claymorphism design system**:

```
+-----------------------------------------------------------------------------------+
|  [< Home]  (Logo) Mokuply          [App Store | Google Play]  [Reset] [Save] [Download] |
+-----------------------------------------------------------------------------------+
| [Add Frame] |                                                |                    |
| [Add Text ] |   SCREEN 1 TAB       SCREEN 2 TAB      (+)     |  INSPECTOR PANEL   |
| [Add Image] |  +--------------+   +--------------+           |                    |
| [Upload]    |  |              |   |              |           |  • Frame Styling   |
|             |  |   App Store  |   |   App Store  |           |  • Typography      |
| [Layout   ] |  |     Row      |   |     Row      |           |  • Gradients       |
| [Backdrop ] |  +--------------+   +--------------+           |  • Layer Order     |
| [Both/One ] |  |  Google Play |   |  Google Play |           |                    |
| [Reset Pos] |  |     Row      |   |     Row      |           |                    |
|             |  +--------------+   +--------------+           |                    |
+-------------+------------------------------------------------+--------------------+
|                                [ - ] ====[Zoom 35%]==== [ + ] [Fit] [100%]        |
+-----------------------------------------------------------------------------------+
```

### 1. Floating Header Navbar
- **Back Button**: Returns to the home portal.
- **Store Platform Switcher**: Toggle the active store view (`Apple App Store` vs `Google Play`).
- **Reset Set**: Restores default layout settings if you want a clean slate.
- **Save Template**: Opens the template creator dialog to save locally or export a `.mokuply` file.
- **Download**: Opens the high-resolution batch export dialog.

### 2. Left Action Rail
A 56px vertical clay bar hosting fast creation and navigation tools:
- **Frame**: Adds an additional phone device frame to the current screen.
- **Text**: Adds a freeform text layer (callouts, feature tags, prices).
- **Image**: Opens the native file picker to place a logo, sticker, or badge.
- **Shot (Upload)**: Prompts for a screenshot to insert into the selected frame.
- **Layout**: Opens the layout presets inspector (Angled, Centered, Full Bleed, etc.).
- **Backdrop**: Opens the canvas background inspector (Gradients, solid colors, cover images).
- **Both / One**: Toggles between viewing both stores simultaneously in stacked rows or focusing on a single store.
- **Reset**: Resets all canvas element positions, scales, and rotations on the active screen back to baseline.

### 3. Dual-Store Strip Canvas
Screens sit side by side as a horizontal strip with interactive tabs above each screen. The canvas supports seamless panning and zooming.

### 4. Contextual Inspector Panel
The right panel automatically adapts based on what you select:
- Nothing selected → **Screen & Layout Settings** (Backgrounds, layout presets, screen title/subtitle).
- Device Frame selected → **Device Frame Inspector** (Phone skin, scale, tilt angle, shadow, screenshot upload).
- Text selected → **Text Inspector** (Font family, size, weight, color, alignment).
- Image selected → **Image Inspector** (Scale, opacity, layer reordering).

### 5. Canvas Zoom Bar
Located at the bottom:
- Zoom slider (`15%` to `150%`).
- `Fit`: Automatically calculates scale to fit your entire project strip onto your display.
- `100%`: Zooms to true 1:1 pixel rendering.

---

## 4. The Dual-Store Workflow & Unified Canvas

### The 1320×2868 Design Space
Apple App Store 6.9" displays require a resolution of **1320×2868 pixels**. Google Play accepts flexible portrait resolutions up to 4K.

Mokuply standardizes on **1320×2868** as the unified coordinate space:
1. Every element's position, font size, and device scale is calculated relative to this reference frame.
2. When exporting for Apple, it outputs a pristine 1320×2868 PNG.
3. When exporting for Google Play, it renders the exact same proportional layout with Galaxy hardware, guaranteeing consistency across both stores.

### Store-Aware Chassis Swapping
When you toggle between stores or view both simultaneously:
- **Apple App Store Target**: Renders the **iPhone 16 Pro Max** with precision Dynamic Island cutout, rounded screen corners, and metallic rim.
- **Google Play Target**: Renders the **Samsung Galaxy S26 Ultra** with centered front camera punch-hole and edge radius.
- Both frames occupy the exact same outer bounding box, so text below or above never needs manual readjustment!

### Independent Screenshot Slots
A realistic mockup often features an iOS-specific UI (SF Pro icons, iOS navigation bar) and an Android-specific UI (Material 3 navigation, Android status bar).

Mokuply frames hold **two screenshot buffers simultaneously**:
- Upload an iOS screenshot when previewing Apple App Store.
- Upload an Android screenshot when previewing Google Play.
- Mokuply remembers both, automatically displaying the matching screenshot for each store!

---

## 5. Managing Screens & The Strip

### Adding & Deleting Screens
- Click the **`+` (Add Screen)** tab at the end of the strip to add a screen.
- To delete, right-click the screen tab (or click the `…` menu) and select **Delete screen**. (Projects must retain at least 1 screen).

### Renaming Screens
- Double-click the tab label directly on the canvas, type the new name (e.g. *01_Onboarding*, *02_Analytics*), and press `Enter`.

### Reordering Screens
- Open the tab menu (`…`) and choose **Move left** or **Move right** to re-sequence your story strip.

### ✨ The "Apply Style to All Screens" Magic Button
Tuning gradients and typography across 6 screens one-by-one is tedious. Mokuply includes a batch styling feature:
1. Customize Screen 1 with your chosen gradient, font family, headline color, and subtitle styling.
2. Click the `…` menu on Screen 1's tab.
3. Select **"Apply this style to all screens"**.
4. Every screen in your project instantly adopts the same background theme and typography styles while preserving its unique text content and device screenshots!

---

## 6. Canvas Elements & Manipulation

### Phone Frames
- **Styles**:
  - `Realistic Phone`: Automatically displays iPhone 16 Pro Max or Galaxy S26 Ultra.
  - `Minimal Dark Frame`: A sleek, universally recognizable neutral device chassis.
  - `Raw Screenshot`: Clean borderless screenshot with soft drop shadow.
- **Scale**: Adjust scale from `0.3×` (compact preview) to `1.6×` (oversized hero bleed).
- **Rotation**: Tilt from `-45°` to `+45°`. Use `-15°` or `+15°` for modern App Store angled hero designs.
- **Shadow**: High-fidelity dual-layer shadow with diffuse ambient glow and deep ground occlusion.
- **Multi-Device Mockups**: Click **Add Frame** on the left rail to add a second or third device to the same screen (ideal for showing chat between two users or iPad/iPhone side-by-side).

### Typography & Google Fonts
Mokuply provides three levels of text:
1. **Title**: The primary hook (e.g. *"Track Expenses with AI"*).
2. **Subtitle**: The supporting value proposition (e.g. *"Instant receipt scanning in 40+ currencies"*).
3. **Custom Text Layers**: Freeform floating labels, badges, or review testimonials.

#### Google Fonts Integration
- Access hundreds of Google Fonts directly.
- **Lazy Loading**: Fonts are only fetched from the network when previewed or exported, keeping the editor blazing fast.
- Popular presets: *Inter, Outfit, Poppins, Montserrat, DM Sans, Plus Jakarta Sans, Space Grotesk, Sora, Playfair Display, Bebas Neue*.

### Custom Image Overlays
- Click **Image** on the Action Rail to upload PNG, JPEG, or WebP graphics.
- Great for:
  - *"App of the Day"* or award badges.
  - Social proof icons (e.g. 5-star rating stars).
  - Floating UI cards, stickers, or brand logos.
- Supports resizing, free rotation, opacity adjustment, and layer reordering.

### Backdrops & Gradients
Under the **Backdrop** rail button or inspector:
- **Gradient Presets**:
  - *Midnight Cyber*: Deep obsidian blue to cyan.
  - *Aurora Borealis*: Emerald teal to vibrant cobalt.
  - *Sunset Glow*: Warm plum to radiant amber.
  - *Neon Violet*: Electric purple to vivid magenta.
  - *Titanium Dark*: Minimalist carbon gray monochrome.
  - *Clean Studio Light*: Crisp white-to-pearl soft studio look.
- **Custom Color**: Pick any solid color using the hex or HSV color picker.
- **Custom Gradient**: Create custom multi-stop gradients with custom start/end alignment angles.
- **Custom Image Background**: Upload high-resolution background photos, textures, or branded artwork.

### Direct Canvas Handles & Magnetic Snapping
When an element is selected on the canvas:
- **Corner Handles**: Drag any of the four corner pills to scale the element proportionally.
- **Rotation Stem**: Drag the circular handle extending from the top to rotate smoothly.
- **Magnetic Snap Guides**:
  - As you drag elements near the horizontal center of the phone screen, a vibrant pink snap line appears.
  - Helps keep device frames and headlines aligned across your entire strip.

---

## 7. Template System & Portability

### Saving to Browser Gallery
1. Click **Save template** in the top navbar.
2. Enter a template name, category (e.g. *Finance*, *Health*, *Social*), and brief description.
3. Click **Save to gallery**.
4. The template is saved in your browser's local database and will appear in your Home template grid permanently.

### Exporting & Importing `.mokuply` Files
- In the **Save template** dialog, click **Download `.mokuply` file**.
- This generates a portable JSON file containing all layout coordinates, fonts, color palettes, and settings.
- Anyone can click **Import template** on the Home screen to load your file and continue editing.

### Contributor Dart Code Generator
For developers and open-source contributors wanting to contribute built-in templates to the Mokuply repository:
1. Design your template in the editor.
2. Open **Save template** > switch to the **Contributor Dart Snippet** tab.
3. Click **Copy Dart Code**.
4. Paste the generated code directly into `lib/data/templates/` and submit a Pull Request!

---

## 8. Draft Autosave & Session Recovery

Mokuply features an automated draft persistence engine:
- Every change (moving an element, modifying text, switching gradients) is debounced and stored in browser `localStorage`.
- If you accidentally close your tab or browser, returning to Mokuply displays a **"Resume your previous draft"** banner.
- Click **Resume Draft** to restore your exact workspace with all images and coordinates intact.

---

## 9. Export Pipeline & Technical Specifications

### High-Resolution Render Pipeline
Unlike browser screen-capture extensions that take blurry screenshots of the DOM:
1. Mokuply spins up an offscreen Flutter repaint boundary at the true native target resolution (**1320×2868**).
2. It re-evaluates all vector paths, text kerning, and image textures at 100% pixel density.
3. Images are exported as pristine, uncompressed 32-bit PNGs.

### Export Dialog Options
Click **Download** in the top navbar to open the export modal:
- **Both Stores (ZIP Bundle)**:
  - Generates a single `.zip` file containing two subfolders:
    - `/Apple_App_Store_1320x2868/`
    - `/Google_Play_Store_1320x2868/`
  - Ready for immediate drag-and-drop into App Store Connect and Google Play Console.
- **App Store Only (ZIP)**: Exports just the iPhone 16 Pro Max 6.9" set.
- **Google Play Only (ZIP)**: Exports just the Galaxy S26 Ultra set.

---

## 10. App Store Optimization (ASO) Playbook

High-converting screenshots can increase app downloads by over 30%. Follow these proven guidelines when designing with Mokuply:

1. **The 3-Second Hook on Screen 1**:
   - 80% of users never swipe past the second screenshot.
   - Screen 1 must answer: *"What is the primary benefit of this app?"*
   - Avoid generic phrases like *"Welcome to the best app"*. Use action verbs like *"Budget smarter in seconds"*.
2. **Readability on Small Displays**:
   - Remember that users view screenshots on mobile search result lists.
   - Keep headlines short (3 to 6 words).
   - Use bold weights (FontWeight 700 to 900) and high contrast with the background.
3. **Show Real UI**:
   - Highlight the most visually striking screens of your app (charts, clean cards, attractive feeds).
   - Zoom in or crop unnecessary empty margins using the frame scale slider.
4. **Visual Strip Continuity**:
   - Use the **"Apply style to all screens"** feature to ensure consistent background hues and typography throughout the 5–8 screenshots in your set.

---

## 11. Complete Keyboard Shortcuts

| Shortcut | Description |
| :--- | :--- |
| `Click + Drag` | Translate element across canvas |
| `Arrow Keys` (`↑` `↓` `←` `→`) | Nudge selection by **1 pixel** |
| `Shift` + `Arrow Keys` | Nudge selection by **10 pixels** |
| `Ctrl` + `D` / `Cmd` + `D` | Duplicate active element (or active screen) |
| `Delete` / `Backspace` | Delete selected element |
| `Esc` | Deselect element / exit full-screen preview |
| `+` / `=` | Zoom in canvas viewport |
| `-` | Zoom out canvas viewport |
| `0` | Fit whole project strip to window |
| `1` | Zoom to 100% actual size (1:1 pixels) |
| `Double Click` (Text) | Direct text editing |
| `Double Click` (Tab) | Rename screen tab |

---

## 12. Troubleshooting & FAQ

### Q: Why do my fonts not load when offline?
> Mokuply utilizes Google Fonts, which fetches web font binaries on first use. Once a font is loaded, your browser caches it locally. For fully offline workflows, the standard system fallbacks are utilized.

### Q: What is the exact screenshot size I should capture from my simulator?
> Any portrait screenshot works! Mokuply automatically scales and centers your screenshot inside the phone chassis bezel with high-quality bicubic resampling. For best results, use standard high-res simulator screenshots (e.g. 1290×2796 or 1179×2556).

### Q: Will Mokuply ever add iPad or Android Tablet mockups?
> Tablet support is planned on our public roadmap! Because Mokuply's layout architecture is built on flexible `DesignSpace` fractions, tablet frame specs will integrate smoothly into the existing multi-canvas workspace.

### Q: Where are my drafts stored?
> In your browser's HTML5 `localStorage` / IndexedDB. Clearing browser site data will reset saved local drafts, so make sure to download important projects as `.mokuply` files.

---

## 13. AI Agent & MCP Automation (Claude & Antigravity)

Mokuply includes a dedicated **Model Context Protocol (MCP)** server (`tools/mcp-server`) that enables AI assistants like **Antigravity**, **Claude (Desktop & Code)**, and Cursor to design, screenshot, and manage mockups automatically:

- **Simulator Screen Capture**: Automatically grab screenshots from running iOS Simulators (`xcrun simctl`) and Android Emulators (`adb`).
- **Cross-Platform**: Full support across **macOS**, **Linux**, and **Windows**.
- **Automated ASO Copy & Layouts**: AI generates high-converting marketing copy and packages dual-store `.mokuply` files.
- **Instant Browser Studio Launch**: Opens Mokuply Web with your mockups pre-loaded via local bridge (`http://127.0.0.1:4004`).

👉 **Read the complete guide: [MCP & AI Agent Guide](MCP_AI_AGENT_GUIDE.md)**

---

<div align="center">
  <sub>Mokuply is built for the global developer community under the MIT License.</sub>
</div>
