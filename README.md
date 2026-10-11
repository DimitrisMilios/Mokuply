# Mokuply

Design high-resolution App Store and Google Play screenshots in your browser.
100% free, fully client-side, open source. Nothing you upload leaves your machine.

- One shared design canvas (1320×2868) for both stores: move, resize or tilt once and both exports follow.
- Realistic phone frames that swap automatically: iPhone 16 Pro Max on the App Store, Galaxy S26 Ultra on Google Play, identical footprint.
- Each frame holds its own iPhone and Android screenshot.
- Headlines, extra text, images and backgrounds, with the full free Google Fonts catalogue.
- Starter templates, custom templates saved in your browser, and `.mokuply` template files you can share.
- Exports lossless PNG bundles for either store or both at once.

## Run locally

Requires Flutter 3.41 or newer.

```bash
flutter pub get
flutter run -d chrome
```

Or serve it without Chrome's debugger:

```bash
flutter run -d web-server --web-port 8765
```

## Test and analyse

```bash
flutter analyze
flutter test
```

## Build and deploy

The app is a static web build hosted on Firebase Hosting.

```bash
flutter build web --release
firebase deploy --only hosting
```

`firebase.json` serves `build/web`, rewrites every route to `index.html`, and sets long-lived caching for hashed assets and no-cache for the Flutter bootstrap files. `.firebaserc` points at the `mockuply` project; change it if you host your own copy.

## Project layout

```
lib/
  core/constants/   store sizes, design space, layout and frame enums, presets
  core/layout/      CanvasGeometry: maps the design space onto any canvas
  models/           TemplateData, CanvasDeviceItem, CanvasImageItem, CanvasTextItem, ProjectTemplate
  viewmodels/       EditorViewModel (single source of truth for the editor)
  services/         export (PNG/ZIP), file picking, local storage, downloads
  views/editor/     canvas workspace, action rail, inspectors, navbar, dialogs
  views/home/       landing page and template gallery
  widgets/canvas/   CanvasMockupWidget and DeviceFrameWidget (used for preview and export)
```

## Contributing

Issues and pull requests are welcome. Please run `flutter analyze` and `flutter test` before opening a PR.

## License

MIT, see [LICENSE](LICENSE).
