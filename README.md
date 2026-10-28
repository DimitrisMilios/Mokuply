<div align="center">

  <img src="assets/branding/mockuply_logo.png" alt="Mokuply Logo" width="128" height="128" />

  # Mokuply

  ### Craft High-Resolution App Store & Google Play Screenshots Directly in Your Browser

  **100% Free · Fully Client-Side · Zero Tracking · Open Source**

  <p align="center">
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.41+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-Hosting-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" /></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-2D6A4F?style=for-the-badge" alt="License" /></a>
    <a href="#"><img src="https://img.shields.io/badge/Privacy-100%25_Client--Side-E8C464?style=for-the-badge" alt="Privacy" /></a>
  </p>

  <p align="center">
    <b><a href="#-quick-tour">Quick Tour</a></b> •
    <b><a href="#-key-features">Key Features</a></b> •
    <b><a href="#-keyboard-shortcuts">Shortcuts</a></b> •
    <b><a href="#-local-development">Run Locally</a></b> •
    <b><a href="docs/GUIDE.md">Full User Guide 📖</a></b>
  </p>

</div>

---

## 🌟 Overview

**Mokuply** is a tactile, browser-based mockup studio engineered specifically for mobile app developers and designers. It solves the biggest headache in app store publishing: **keeping Apple App Store and Google Play Store screenshot sets in sync without designing everything twice.**

With Mokuply's **Unified Design Space (1320×2868)**, every screen is designed once. When you export or preview, Mokuply automatically swaps chassis hardware (iPhone 16 Pro Max for Apple, Samsung Galaxy S26 Ultra for Google Play) with identical footprints, preserving perfect alignment, typography, and visual balance across both ecosystems.

Best of all: **Mokuply is 100% client-side.** Everything is rendered in-memory via Flutter CanvasKit. Your confidential unreleased app screenshots, assets, and branding never touch an external server or analytics tracker.

---

## ✨ Why Mokuply?

| Feature | Mokuply | Traditional Design Tools (Figma/Canva) | Other Screenshot SaaS |
| :--- | :---: | :---: | :---: |
| **Privacy & Security** | 🔒 **100% In-Browser (Zero Uploads)** | ☁️ Cloud Synced | ☁️ Cloud Synced / Logged |
| **Unified Dual-Store Canvas** | ⚡ **One design, auto-swaps iPhone & Galaxy** | ❌ Manual re-layout | ❌ Requires separate projects |
| **Cost** | 💸 **Free Forever (MIT)** | 💳 Subscriptions / Seat limits | 💳 \$19–\$49/month paywalls |
| **Output Quality** | 🎯 **1320×2868 Lossless PNGs** | Manual export setup | Often compressed or watermarked |
| **Offline-Capable Drafts** | 💾 **Local browser persistence** | ❌ Requires internet | ❌ Requires login & internet |
| **Template Portability** | 📦 **Self-contained `.mokuply` files** | Proprietary files | Locked to service |

---

## 🚀 Key Features

### 📐 Unified Design Space (1320×2868)
- Author your design strip once in the high-fidelity **1320×2868** coordinate system (matching the 6.9" App Store display standard).
- Both store rows update simultaneously in real-time.
- Uniform scaling ensures Google Play renders are pixel-accurate without distortion.

### 📱 Store-Aware Chassis Swapping
- **Apple App Store**: Renders realistic **iPhone 16 Pro Max** with precision Dynamic Island cutout and titanium rim.
- **Google Play Store**: Renders realistic **Samsung Galaxy S26 Ultra** with centered hole-punch display and flagship chassis.
- Both devices share identical bounding boxes so your typography, angles, and graphic overlays never shift when switching stores.
- Also supports **Minimal Dark Outline** and **Raw Screenshot (Border-less)** styles.

### 🎨 Tactile Claymorphism Design System
- Built from the ground up with a soft, warm claymorphism aesthetic.
- Physical depth with dual directional inner highlights, drop shadows, and spring motion feedback.
- Interactive canvas with fluid rotation stems, corner scaling handles, and horizontal/vertical magnetic snap lines.

### 🔤 Rich Typography & Smart Font Catalog
- Independent styling for headlines, subtitles, and freeform text blocks.
- Full access to the **Google Fonts** library with a zero-bloat, debounced lazy loader (only loads fonts as you browse).
- Font size, weight, letter spacing, alignment, and color controls.

### 🖼️ Multi-Layer Canvas Elements
- Add multiple phone frames, custom images, badges, logos, or stickers per screen.
- Move, scale, tilt, duplicate, or re-order layers directly on the canvas or via the contextual inspector panel.
- Right-click or use keyboard shortcuts for rapid workflows.

### 🎨 Flexible Backgrounds & Gradients
- Curated high-contrast studio presets (*Midnight Cyber*, *Sunset Glow*, *Aurora Borealis*, *Titanium Dark*, etc.).
- Custom solid colors, dynamic multi-stop linear gradients with customizable angle vectors.
- Custom background image uploads with full bleed.

### ⚡ Batch Management & "Apply Style to All"
- Design a beautiful aesthetic on Screen 1 and click **"Apply style to all screens"** to instantly propagate gradients, fonts, and layouts across your entire app showcase strip.
- Drag to reorder screens, duplicate screen configurations, or rename individual screen tabs.

### 💾 Browser Autosave & Portable `.mokuply` Files
- In-flight work autosaves to browser `localStorage` so you never lose progress on accidental tab closure.
- Export and import `.mokuply` JSON template files to share with teammates.
- Built-in **Dart Code Generator** so open-source contributors can turn custom designs into native built-in templates!

### 📦 Lossless High-Res Packaging
- Offscreen Flutter repaint boundary rendering ensures zero downscaling artifacts.
- Export Apple App Store bundle (`.zip`), Google Play Store bundle (`.zip`), or both simultaneously with organized folder structures.

---

## ⌨️ Keyboard Shortcuts

Speed up your design process with intuitive hotkeys:

| Shortcut | Action |
| :--- | :--- |
| `Click + Drag` | Move element across canvas |
| `Arrow Keys` (`↑` `↓` `←` `→`) | Nudge selected element by **1px** |
| `Shift` + `Arrow Keys` | Nudge selected element by **10px** |
| `Ctrl` / `Cmd` + `D` | Duplicate selected element (or duplicate active screen) |
| `Delete` / `Backspace` | Delete selected element |
| `Esc` | Deselect element / exit preview mode / close popover |
| `+` / `=` | Zoom in canvas viewport |
| `-` | Zoom out canvas viewport |
| `0` | Fit entire screenshot strip to screen |
| `1` | Zoom to 100% actual size |
| `Double Click` (Text) | Edit headline / subtitle inline |
| `Double Click` (Tab) | Rename screen tab |

---

## 🛠️ Architecture & Tech Stack

Mokuply is built on Flutter Web leveraging the high-performance **CanvasKit** rendering engine:

```
lib/
├── core/
│   ├── constants/       # Store resolutions, design space specs, colors & dimensions
│   ├── layout/          # CanvasGeometry, drag math & alignment snap anchors
│   ├── motion/          # Spring physics, clay pressables & staggered entrances
│   └── theme/           # Nunito typography & clay token hierarchy
├── data/
│   └── templates/       # Built-in starter templates (SaaS, Team Organize, Minimalist)
├── models/              # TemplateData, CanvasDeviceItem, CanvasTextItem, ProjectTemplate
├── services/            # Offscreen high-res render pipeline, ZIP archiver, localStorage
├── viewmodels/          # EditorViewModel, LibraryViewModel, ExportViewModel (Provider)
├── views/
│   ├── home/            # Welcome portal, 3D clay hero render & template gallery
│   └── editor/          # Dual-row workspace, action rail, inspectors & export modals
└── widgets/
    ├── clay/            # Custom claymorphism UI kit (buttons, panels, dialogs, sliders)
    ├── canvas/          # DeviceFrameWidget, selection chrome, handles & snap overlays
    └── shared/          # Google Fonts lazy picker catalog, color swatches & brand assets
```

---

## 💻 Local Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.41.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.11.5`)
- Google Chrome (or any modern Chromium browser)

### 1. Clone the repository
```bash
git clone https://github.com/DimitrisMilios/Mokuply.git
cd Mokuply
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run in Chrome (with DevTools & Hot Reload)
```bash
flutter run -d chrome
```

### 4. Or serve locally with CanvasKit
```bash
flutter run -d web-server --web-port 8765
```
Then navigate to `http://localhost:8765` in your browser.

### 5. Run tests & static analysis
```bash
flutter analyze
flutter test
```

---

## 🚢 Building & Deployment

Mokuply compiles into a static single-page application (SPA) optimized for Firebase Hosting or any static CDN (Vercel, Netlify, Cloudflare Pages, GitHub Pages).

### Build for Production
```bash
flutter build web --release
```

### Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

The included `firebase.json` automatically configures SPA URL rewriting, aggressive caching for hashed immutable assets (`woff2`, `png`, `wasm`), and no-cache rules for `flutter_bootstrap.js` to guarantee seamless client updates.

---

## 📖 Complete Documentation

Looking for an in-depth walkthrough of every feature, layout mode, device setting, and ASO tips?

👉 **Read the [Complete Mokuply User Guide & Feature Manual](docs/GUIDE.md)**

---

## 🤝 Contributing

Contributions, bug reports, and template designs are welcome!

1. **Fork the repository**
2. **Create your feature branch** (`git checkout -b feat/amazing-feature`)
3. **Commit your changes** (`git commit -m 'feat: Add amazing feature'`)
4. **Verify formatting & tests** (`flutter analyze && flutter test`)
5. **Push to the branch** (`git push origin feat/amazing-feature`)
6. **Open a Pull Request**

> **Tip for Designers & Developers:** Want to submit a built-in template? Use the in-app **"Save Template > Contributor Snippet"** dialog to generate ready-to-merge Dart code!

---

## 📄 License

Mokuply is distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

<div align="center">
  <sub>Crafted with precision for app creators worldwide. If you find Mokuply useful, consider giving it a ⭐ on GitHub!</sub>
</div>
