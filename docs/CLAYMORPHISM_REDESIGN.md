# Mockuply · Claymorphism redesign guide

Branch: `feat/claymorphism-redesign`
Scope: the app's own UI (home, editor chrome, dialogs). The exported screenshots, the phone frames inside the canvas, and the editor logic do not change.

This document is the single checklist for turning the current "light liquid glass" look into a claymorphism look. Part A explains the target style and the design tokens. Part B is the file by file inventory of what changes. Part C is the list of things to delete outright (chips, badges, generic copy). Part D is the Blender asset list and workflow. Part E is the implementation order. Part F is the motion spec: springs, per‑control animations and screen transitions.

---

## Part A · The target look

### A.1 What claymorphism is, and how it differs from what we have

| | Current (glassmorphism) | Target (claymorphism) |
|---|---|---|
| Surface | Translucent white, `BackdropFilter` blur | Opaque, matte, slightly warm. No blur anywhere |
| Edge | 1 px tinted border | **No border.** The edge is implied by two inner shadows: a light one top‑left, a dark one bottom‑right |
| Depth | One soft outer drop shadow | One big, soft, far outer shadow (the object floats) plus the inner pair (the object is thick) |
| Corners | 12 to 24 px | Big and chunky: 20 to 36 px. Buttons and inputs are near pill |
| Colour | Cream base, jungle green tint everywhere | Pastel clay tints. Green stays the brand accent, gold from the leaf logo is the second accent |
| Background | Blurred colour orbs | Flat warm sand, optionally a faint paper grain. Hero gets real 3D clay objects rendered in Blender |
| Pressed state | Opacity change | The element physically sinks: outer shadow shrinks, inner shadows invert |
| Imagery | Material icons | 3D clay icons and illustrations (Blender) for the places that carry personality; Material icons stay for dense tool UI |

The brand logo (`assets/branding/mokuply_logo.png`) is already a soft gold clay leaf on jungle green. It is the anchor. Everything in the new UI should look like it was made from the same material as that leaf.

### A.2 Design tokens (new values for `lib/core/constants/`)

#### Colours (`app_colors.dart`)

Remove every `glass*`, `orb*`, `surface`, `surfaceBorder`, `surfaceSelected`, `badgeBg` token. Add:

```dart
// Base
static const Color sand        = Color(0xFFEFE8D6); // page background
static const Color sandDeep    = Color(0xFFE6DEC8); // canvas viewport background (slightly darker so the strip "sits in" the page)
static const Color clay        = Color(0xFFFBF6EA); // default clay surface (panels, cards, inputs)
static const Color clayDeep    = Color(0xFFF1EAD8); // sunken surface (inset wells, slider track, list background)

// Clay lighting (used by ClayDecoration, never by widgets directly)
static const Color clayLight   = Color(0xFFFFFFFF); // inner highlight, top-left, ~0.9 alpha on clay surfaces
static const Color clayShade   = Color(0xFF1A4731); // inner shade, bottom-right, ~0.16 alpha on clay surfaces
static const Color clayShadow  = Color(0xFF1A4731); // outer floating shadow, ~0.20 alpha

// Brand clay (buttons, active states)
static const Color primary       = Color(0xFF2D6A4F); // was 0xFF1A4731. Lighter so the inner shade still reads
static const Color primaryDeep   = Color(0xFF1A4731); // inner shade + pressed fill for primary
static const Color primaryLight  = Color(0xFF52B788); // inner highlight on primary clay
static const Color mint          = Color(0xFFCDE7D6); // soft green clay (selected rows, hover fill)

// Second accent, from the leaf
static const Color gold          = Color(0xFFE8C464);
static const Color goldDeep      = Color(0xFFC9A440);
static const Color goldLight     = Color(0xFFFFE79A);
static const Color butter        = Color(0xFFFFF0C2); // soft gold clay (info wells, hints)

// Semantic clay
static const Color coral         = Color(0xFFF08A7E); // danger buttons
static const Color coralDeep     = Color(0xFFD9675B);
static const Color sage          = Color(0xFF8FBF9F); // success

// Text
static const Color textPrimary   = Color(0xFF1F3A2E);
static const Color textSecondary = Color(0xFF3F6350);
static const Color textMuted     = Color(0xFF7A917F);
static const Color textOnPrimary = Colors.white;

// Canvas chrome (unchanged)
static const Color snapGuide     = Color(0xFFE11D74);
static const Color frameIphone   = Color(0xFF1A4731);
static const Color frameSamsung  = Color(0xFF2D6A4F);
```

#### Radii and spacing (`app_dimensions.dart`)

Remove `radiusGlass*` and `cardRadius`. Add:

```dart
static const double radiusClaySm = 16.0; // chips of real function, list rows, inputs
static const double radiusClay   = 24.0; // buttons, tiles, small cards
static const double radiusClayLg = 32.0; // panels, dialogs, big cards
static const double radiusClayXl = 40.0; // hero card, navbar
static const double clayDepth    = 6.0;  // default inner shadow offset
static const double clayLift     = 18.0; // default outer shadow offset (y)
```

Keep the spacing and font scale tokens as they are.

#### Typography (`app_theme.dart`)

Inter is a "SaaS dashboard" font and fights the playful material. Switch to **Nunito** (already available through `google_fonts`):

- Display and headings: Nunito 800 or 900, letter spacing ‑0.5 to ‑1.5.
- Body and UI: Nunito 600 for labels, 500 for body. Nunito's rounded terminals match the rounded corners.
- Tabular figures stay on anything numeric (zoom %, export sizes).

### A.3 The clay surface, in Flutter terms

Flutter's `BoxDecoration` cannot do inset shadows. Build one reusable decoration and use it everywhere:

```
lib/widgets/shared/clay_container.dart   (replaces glass_container.dart)
lib/widgets/shared/clay_decoration.dart  (custom painter)
```

`ClayDecoration` paints, in this order, inside a rounded rect:

1. **Fill** with the surface colour.
2. **Inner highlight**: clip to the rrect, draw the same rrect offset by `(-depth, -depth)` with a stroke of width `depth * 2`, colour `clayLight`, `MaskFilter.blur(normal, depth)`. Only the top‑left part survives the clip.
3. **Inner shade**: same trick offset by `(+depth, +depth)` with `clayShade` at low alpha.
4. **Outer shadow** painted *before* the fill: `clayShadow` at 0.20, blur 28, offset `(0, clayLift)`. For raised buttons use a tighter second shadow (blur 8, offset `(0, 4)`) so the edge reads.

Parameters: `color`, `radius`, `depth`, `lift`, `pressed` (when true: lift → 2, inner shadows swap sides, fill darkens 6 %), `sunken` (inset well: no outer shadow, inner shade on top‑left, highlight bottom‑right).

Hover and press animate `lift` and `depth` with `AnimatedClay` (an `ImplicitlyAnimatedWidget`, 120 ms, `Curves.easeOut`). This replaces every `InkWell` splash in the chrome. Splash ripples look wrong on clay; keep `InkWell` only for hit testing with `splashFactory: NoSplash.splashFactory`.

Alternative if time is short: the `clay_containers` pub package does this with gradients. It is less controllable and its look is flatter, so the custom painter is preferred.

### A.4 Component vocabulary

Every piece of chrome maps onto one of these. Build them once in `lib/widgets/clay/` and reuse.

| Component | File | Notes |
|---|---|---|
| `ClayPanel` | `clay_panel.dart` | Big surface: navbars, inspector, action rail, dialogs. `radiusClayLg`, lift 18, depth 6 |
| `ClayCard` | `clay_card.dart` | Template cards, export option cards. `radiusClayLg`, hover lifts +6 |
| `ClayButton` | `clay_button.dart` | Variants `primary` (green clay), `gold`, `neutral` (clay colour), `danger` (coral). Pill radius. Press sinks. Icon + label |
| `ClayIconButton` | `clay_icon_button.dart` | Square clay tile 40 or 44 px with an icon. Replaces every `IconButton` in the chrome |
| `ClaySegmented` | `clay_segmented.dart` | A sunken track with a raised clay "puck" that slides to the active option. Replaces every `SegmentedButton` |
| `ClayToggle` | `clay_toggle.dart` | Sunken pill track, raised clay knob. Replaces `SwitchListTile` |
| `ClaySlider` | `clay_slider.dart` | Sunken track, raised round knob, filled portion in primary. Replaces `LabeledSlider` and the theme slider |
| `ClayField` | `clay_field.dart` | Sunken well with the text inside, label above in muted caps. Replaces `InputDecorationTheme` borders |
| `ClayWell` | `clay_well.dart` | Sunken container for grouping (layers list background, dark code box) |
| `ClayTile` | `clay_tile.dart` | Selectable row/tile (layout presets, frame styles, font rows, layer rows). Raised when selected, flat when not |
| `ClayDropdown` | `clay_dropdown.dart` | Raised clay button that opens a clay popover |
| `ClayPopover` | `clay_popover.dart` | Shared popup surface for menus (`showMenu` in screen tabs and canvas context menu) |
| `ClayToast` | `clay_toast.dart` | Replaces every `SnackBar`. Clay surface, icon tile, one line of text |
| `ClayTooltip` | `clay_tooltip.dart` | `TooltipTheme`: small clay surface, no arrow |
| `ClayDialog` | `clay_dialog.dart` | `Dialog` wrapper with `ClayPanel`, barrier colour `sandDeep` at 0.6 instead of black |

---

## Part B · File by file inventory

Legend: **Replace** = rewrite the visual layer of this file. **Touch** = small edits. **Delete** = remove the file.

### B.1 Foundations

| File | Action | What changes |
|---|---|---|
| `lib/core/constants/app_colors.dart` | Replace | Tokens from A.2 |
| `lib/core/constants/app_dimensions.dart` | Touch | Radii from A.2 |
| `lib/core/theme/app_theme.dart` | Replace | Nunito text theme. `scaffoldBackgroundColor: sand`. `inputDecorationTheme` with no borders and `clayDeep` fill (ClayField draws the well). `sliderTheme` removed (ClaySlider). `dialogTheme` transparent. Add `tooltipTheme`, `popupMenuTheme`, `snackBarTheme` all clay. `splashFactory: NoSplash.splashFactory` |
| `lib/widgets/shared/glass_container.dart` | Delete | Replaced by `clay_container.dart` + `clay_decoration.dart` |
| `lib/widgets/shared/ambient_background.dart` | Replace | Remove the three orbs. Paint flat `sand` plus an optional very faint noise texture (a tiny tiled PNG from Blender, see D.3). On the home page only, place the hero 3D renders here as `Positioned` images |
| `lib/widgets/shared/canvas_grid_painter.dart` | Touch | Grid lines at `clayShade` 0.06 on `sandDeep`, step 32 → 40. Or replace with a dot grid (2 px dots) which looks softer |
| `lib/widgets/shared/labeled_slider.dart` | Replace | Becomes `ClaySlider` with the label row kept. The value pill on the right is a chip, see C.1: show the value as plain muted text, tabular figures |
| `lib/widgets/shared/color_swatch_button.dart` | Replace | Swatch becomes a round clay knob showing the colour (raised, with the inner shadow pair tinted by the colour). Picker dialog becomes `ClayDialog` |
| `lib/widgets/shared/font_picker_field.dart` | Replace | Field becomes a `ClayDropdown`. Dialog becomes `ClayDialog`; rows become `ClayTile`; search becomes `ClayField`. Keep the lazy preview logic untouched |
| `lib/widgets/shared/brand_logo.dart` | Touch | Drop the box shadow option; the mark sits in a small clay tile (`ClayIconButton` surface without the button) so it floats like everything else |
| `lib/services/css_spinner.dart` | Touch | Spinner colour is a leftover teal `#0d9488` (line 27). Change to `primary` green, track to `mint`. Width 3 → 4 |
| `web/index.html`, `web/manifest.json` | Touch | `theme-color` and `background_color` from `#1A4731` to the new `sand` `#EFE8D6` so the browser chrome matches the page, not the logo |

### B.2 Home (`lib/views/home/`)

| File | Action | What changes |
|---|---|---|
| `home_view.dart` | Replace | Page padding stays. Scaffold background `sand`. The grid uses `ClayCard`. **Delete** the "Free E‑Shop Store" chip (line 194). The "Import .mokuply template" outlined button becomes a `ClayButton.neutral`. Section title stays, subtitle copy changes (see C.2). The draft banner (`_SavedDraftBanner`) becomes a `ClayPanel` with a gold clay icon tile on the left, `ClayButton.primary` Resume and a plain text Discard |
| `widgets/home_navbar.dart` | Replace | `ClayPanel` with `radiusClayXl`, height 72. Logo tile + wordmark. **Delete** the "100% Free & Client‑Side" chip. The Start Project button becomes `ClayButton.gold` (gold is the "go" colour on the home page, so it pops against the green brand). Keep the responsive collapse logic |
| `widgets/hero_section.dart` | Replace | Two column layout above 960 px: text left, a Blender hero render right (D.1, asset `hero_phone_stack.png`). Below 960 px the render goes under the text at 60 % width. Headline stays two lines. **Delete** the "Do you want to start a project?" glass card: it is a card inside a card. Replace with one `ClayButton.primary` "Start a project" and a text link "Browse templates" that scrolls to the grid |
| `widgets/template_card.dart` | Replace | `ClayCard`. The preview strip (the six tiny fake phones) stays but becomes a sunken `ClayWell` with the gradient inside it, and the fake phones get the inner shadow pair so they read as clay slabs. **Delete** the "6 Screenshots" overlay chip and the category chip; category becomes the muted caps line above the title, screenshot count moves into the description line ("6 screens · App Store"). Button becomes `ClayButton.primary` "Use template" |
| `widgets/home_footer.dart` | Touch | Remove the top border. Two lines of muted text. Copy change (C.2) |

### B.3 Editor shell (`lib/views/editor/`)

| File | Action | What changes |
|---|---|---|
| `editor_view.dart` | Touch | `AmbientBackground` → plain `sand`. Panel positions are unchanged but the inspector's `_visibleRegion()` math (line 62) must use the new rail width if the rail gets wider (see action rail). Background `sand` |
| `widgets/editor_navbar.dart` | Replace | `ClayPanel`. Back arrow → `ClayIconButton`. **Delete** the "N Screenshots Set" chip; the count already lives in the inspector header and the Download button. Store switch → `ClaySegmented` with icon + label. Reset → text button with icon. Save template → `ClayButton.neutral`. Download → `ClayButton.primary`. Keep the three breakpoints |
| `widgets/action_rail.dart` | Replace | `ClayPanel`, width 76 → 84. Each `_RailButton` becomes a 56 px clay tile: raised when idle, sunken when active (not green filled). Icons: this is the one place to use **3D clay icons from Blender** (D.2) at 28 px, Material icons as fallback. Section labels stay as muted caps. Dividers → 16 px gap, no line |
| `widgets/inspector_panel.dart` | Replace | `ClayPanel`. Header: screen name, `n/N` as muted text, collapse → `ClayIconButton`. Remove the bottom border line on the header; use spacing. Section headers stay muted caps. The target row (icon tile + title + subtitle) keeps its layout; the icon tile becomes a small sunken clay square. Dividers → spacing |
| `widgets/layers_list.dart` | Replace | The list sits in a sunken `ClayWell`. Rows are `ClayTile`: flat text on the well when idle, a raised mint clay puck when selected (not solid green). Delete icon appears on hover as now, coral |
| `widgets/editor_mode_bar.dart` | Replace | `ClaySegmented` (sunken track, sliding puck) with Edit / Preview |
| `widgets/canvas_zoom_bar.dart` | Replace | `ClayPanel` small, three `ClayIconButton`s and the percentage as a `ClayButton.neutral` compact. Remove the vertical divider |
| `widgets/multi_canvas_workspace.dart` | Touch | Viewport colour `sandDeep`. Screen cards: selected state currently is a 3 px green border + big glow (lines 109‑124). New: no border; selected card lifts (shadow blur 34 → 40, offset y 12 → 20) and gets a 4 px `gold` underline bar under the tab. Screen tabs (`_ScreenTab`, line ~384): raised clay pill when selected, flat text when not. Add‑screen button → `ClayIconButton`. Store row header pills (`_StoreRowHeader`, line ~506): active one is a raised primary clay pill, inactive is flat muted text with icon. "Both stores" pill → text link with icon. Tab menu → `ClayPopover` |
| `widgets/export_modal_dialog.dart` | Replace | `ClayDialog`, width 640. Header icon tile → sunken clay square. Progress card → `ClayWell` with `ClaySlider`‑style bar. Option cards → `ClayCard` with a round clay icon knob on the left. **Delete** the "RECOMMENDED" chip and the dimensions badge; the recommended card is simply first, slightly larger, with the green button while the other two have neutral buttons. Dimensions go into the description text. Buttons → `ClayButton`. Snackbars → `ClayToast`. Copy changes (C.2) |
| `widgets/template_builder_dialog.dart` | Replace | `ClayDialog`. Inputs → `ClayField`. The dark code box stays dark (it is code), but as a sunken `ClayWell` with `primaryDeep` fill and `goldLight` monospace text instead of the slate/sky‑blue Tailwind colours (lines 352 and 362). Buttons → `ClayButton`. Snackbars → `ClayToast` |

### B.4 Inspector panels (`lib/views/editor/panels/`)

| File | Action | What changes |
|---|---|---|
| `text_inspector.dart` | Replace | Text field → `ClayField` (multiline). Font row → `ClayDropdown`. Size slider → `ClaySlider`. The weight dropdown (line 176) → `ClayDropdown`. Alignment trio → `ClaySegmented` icon‑only. Colour → clay knob. Delete → `ClayButton.danger` outlined style is gone; use a flat coral text button with icon, full width. The two explanatory paragraphs (export size, canvas hints) merge into one shorter line (C.2) |
| `frame_inspector.dart` | Replace | Section titles stay. `_ScreenshotSlotTile` (line 203) → `ClayTile`, raised when it has an image; **delete** the "PREVIEWING" chip and show a small gold dot before the label instead. Upload/remove → `ClayIconButton`. `_StyleTile` (line 140) → `ClayTile` with the check mark replaced by the raised state. Sliders → `ClaySlider`. Shadow switch → `ClayToggle`. Remove frame → flat coral text button |
| `image_inspector.dart` | Replace | Preview → sunken `ClayWell`. Sliders → `ClaySlider`. Switch → `ClayToggle`. Delete → flat coral text button |
| `screen_inspector.dart` | Replace | Duplicate / Delete → two `ClayButton.neutral` (delete in coral text). Section switch → `ClaySegmented`. Layout presets (`ListTile` with border, line 113) → `ClayTile` list, raised when selected. Hint copy shortened |
| `background_panel.dart` | Replace | Upload button → `ClayButton.primary`, "Change" state → `ClayButton.neutral`. **Delete** the "Image Active" green status box; show a thumbnail of the chosen image in a sunken well with a coral "Remove" text button. Gradient grid → each preset is a small raised clay slab with the gradient as fill and the inner shadow pair on top; selected one is sunken. Solid colour row → clay knob |

### B.5 Canvas selection chrome (`lib/widgets/canvas/canvas_mockup_widget.dart`)

The on‑canvas handles are tool UI, not decoration, so they stay crisp. Small touches only:

- Corner handles (line ~1005): white fill, `primary` border → keep but radius 3 → 4 and add a 2 px soft shadow so they feel like tiny clay beads.
- Rotate handle (line ~1067): same.
- Selection outline (line ~849): `primary` 1.5 px → `gold` 2 px. Gold is the "selected" colour across the app (tabs, cards, handles), green is the "action" colour.
- Context menu → `ClayPopover`.
- Snap guide stays magenta.

Nothing inside the exported screenshot changes.

---

## Part C · Delete list and copy rewrite

### C.1 Chips and badges to remove

These are the pills the user dislikes. None carries information that is not available elsewhere.

| Chip | Where | Replacement |
|---|---|---|
| "100% Free & Client‑Side" | `home_navbar.dart` line 57 | Delete. The line moves to the hero subtitle and the footer |
| "N Screenshots Set" | `editor_navbar.dart` line 79 | Delete. Count is in the inspector header and the download button |
| "Free E‑Shop Store" | `home_view.dart` line 194 | Delete (it is not even a button) |
| Category chip + "6 Screenshots" overlay | `template_card.dart` | Category → muted caps line. Count → description line |
| "PREVIEWING" | `frame_inspector.dart` line 263 | Gold dot before the store label |
| "RECOMMENDED" + dimensions badge | `export_modal_dialog.dart` lines 325 and 344 | First card is bigger and green; dimensions in the description |
| Slider value pill | `labeled_slider.dart` | Plain muted tabular text |
| "Image Active" status box | `background_panel.dart` line 60 | Thumbnail in a sunken well |
| Dark overlay chip on template preview | `template_card.dart` line 108 | Delete |

Rule going forward: a pill is allowed only when it is **interactive** (a segmented option, a tab, a toggle). Static labels are text.

### C.2 Copy that reads as generated marketing, and what to say instead

| Current | New |
|---|---|
| "Create Store Screenshots in Seconds" | "Store screenshots, made by hand." (or keep the current if preferred, but drop "in Seconds") |
| "Generate high‑resolution 6.9" & 6.8" mockup sets for Apple App Store and Google Play Store directly in your browser." | "Lay out your App Store and Google Play screenshots on one canvas. Free, open source, and nothing leaves your browser." |
| "Do you want to start a project?" / "Let's Start" | Single button: "Start a project" |
| "Starter Mockup Templates" / "Pre‑configured sets designed for maximum conversion" | "Templates" / "Start from a layout and change anything." |
| "Saved Session Found in Local Storage" / "Resume Work" | "You have an unfinished project" / "Resume" |
| "Download All (N) PNGs" | "Download (N)" |
| "Download Store Screenshots" / "Select store dimensions for your pixel‑perfect PNG export package." | "Download" / "Pick a store, or get both in one zip." |
| "Download for Both Stores (ZIP Bundle)" / "Master ZIP package containing organized folders for both App Store Connect & Google Play Console." | "Both stores" / "One zip with an App Store folder and a Google Play folder." |
| "Apple App Store Only" / "Formatted for the App Store Connect 6.9" display specification." | "App Store" / "1320×2868 PNGs for the 6.9" slot." |
| "Google Play Store Only" / "Same 1320×2868 canvas as Apple with the Galaxy frame, ready for the Google Play Console." | "Google Play" / "Same size, Galaxy frame." |
| "Downloading Mokuply_StoreScreenshots_AllPlatforms.zip to Downloads folder!" (and the two siblings) | "Your zip is downloading." No exclamation marks in any toast |
| "Save Current Design as Template" / "Save & Persist to Gallery" / "Saved to Browser Storage!" | "Save as template" / "Save" / "Saved" |
| "Generated Template Dart Code" / "Ready for project_template.dart" | "Dart snippet" / "For contributors adding a built‑in template" |
| "Template "X" saved & persisted to your browser storage!" | "Saved "X"." |
| "Template "X" loaded successfully!" | "Loaded "X"." |
| "Mocuply Studio © 2026 — 100% Free & Client‑Side" / "Built with Flutter Web" | "Mockuply · free and client‑side · MIT" / "Source on GitHub" (link) |
| Inspector hint "On the canvas: drag to move, corner handles to resize, the top handle to rotate. Double‑click the text to edit it here." | "Drag to move, corners to resize, top handle to rotate." |
| Text inspector export‑size paragraph | "Px on the 1320×2868 export (≈ Npx on the card)." one line |
| "Presets reposition the headline and phone. You can still drag anything afterwards." | "Presets move the headline and phone. Drag to adjust." |
| "One image per store. Position and size are shared, so both stores stay identical." | "One image per store. Position and size are shared." |

Also: the product name is **Mockuply**. Today the code uses three spellings: the UI, `app.dart`, `pubspec.yaml` and `web/` say "Mocuply"; the README, the logo file (`assets/branding/mokuply_logo.png`), the template file extension (`.mokuply`), the exported zip name and the CSS spinner ids say "Mokuply"; only the Firebase project id says "mockuply". Fix every user-facing string to Mockuply in this pass: `app.dart` title, both navbars, the footer, `index.html`, `manifest.json`, the export zip name, the toast strings. Rename the logo asset to `assets/branding/mockuply_logo.png` and update `pubspec.yaml` and `brand_logo.dart`. Leave the `.mokuply` template extension and the `mocuply` Dart package id alone, since saved template files and imports already use them.

---

## Part D · Blender assets

All renders: Cycles or Eevee Next, transparent film, PNG RGBA 16‑bit, sRGB. Export at 2× the display size. File names are lowercase snake case under `assets/clay/`. Add the folder to `pubspec.yaml` under `flutter: assets:`.

### D.1 Shared material and lighting (set up once, save as `mockuply_clay.blend`)

- **Clay material**: Principled BSDF. Base colour from the token table. Roughness 0.65. Specular IOR level 0.3. Subsurface weight 0.08 with radius `(1.0, 0.6, 0.4)` scaled to the object (this is what makes it read as clay instead of plastic). Sheen 0.1. No metallic, no clearcoat.
- **Bevel**: every mesh gets a Bevel modifier, 3 segments, width about 8 % of the object's smallest dimension, plus Shade Smooth. Chunky soft edges are the whole style.
- **Lighting**: large area light top‑left (size 3 m, strength 400 W, slightly warm 5200 K), a weaker area light bottom‑right (size 2 m, 120 W, slightly cool 7000 K) so the inner highlight / inner shade direction matches the UI (`ClayDecoration` lights from top‑left too). HDRI world at 0.3 strength for soft fill, no visible reflections.
- **Camera**: orthographic for icons (scale 2.2, rotated 35° X / 45° Z for the ¾ view) and a 50 mm perspective for the hero.
- **Colour management**: Filmic or AgX, look "Medium contrast". Match the final PNG against the token hex values in the UI; adjust base colour, not the lights.
- **Ground contact**: no ground plane. The UI draws the floating shadow in code, so a baked shadow would double up.

### D.2 Asset list

| Asset | File | Size (display) | Used in | Notes |
|---|---|---|---|---|
| Hero composition | `hero_phone_stack.png` | 720×560 | `hero_section.dart` | A clay iPhone‑ish slab and a Galaxy‑ish slab leaning on each other, two or three floating clay "screenshot cards" with the gold leaf resting on one. Green, cream, gold palette only. Slight camera tilt |
| Rail icon: Frame | `icon_frame.png` | 28 | `action_rail.dart` | Clay phone slab, green |
| Rail icon: Text | `icon_text.png` | 28 | `action_rail.dart` | A chunky clay "T" or "Aa", cream with gold |
| Rail icon: Image | `icon_image.png` | 28 | `action_rail.dart` | Clay picture frame with a sun and hill |
| Rail icon: Shot (upload) | `icon_upload.png` | 28 | `action_rail.dart` | Clay tray with an arrow up |
| Rail icon: Layout | `icon_layout.png` | 28 | `action_rail.dart` | Three stacked clay bars |
| Rail icon: Backdrop | `icon_backdrop.png` | 28 | `action_rail.dart` | Clay palette with three colour dots |
| Rail icon: Both / One | `icon_rows_both.png`, `icon_rows_one.png` | 28 | `action_rail.dart` | Two slabs / one slab |
| Rail icon: Reset | `icon_reset.png` | 28 | `action_rail.dart` | Clay circular arrow |
| Template preview phones | `tpl_phone_mini.png` | 44×90 | `template_card.dart` | One cream clay phone slab, tinted in code with `ColorFiltered` per template so one render serves all cards |
| Export: both stores | `export_both.png` | 56 | `export_modal_dialog.dart` | Clay box with the Apple and Android marks as embossed shapes (not logos: an apple silhouette and a bugdroid‑free rounded shape) |
| Export: App Store | `export_apple.png` | 56 | `export_modal_dialog.dart` | Clay iPhone slab |
| Export: Google Play | `export_play.png` | 56 | `export_modal_dialog.dart` | Clay Galaxy slab |
| Empty state: no screenshot | `empty_frame.png` | 160 | frame placeholder in `device_frame_widget.dart` (preview only, never exported) | Clay phone with a dotted outline and a small gold leaf. Replaces the current "upload" placeholder drawing |
| Draft banner icon | `icon_history.png` | 40 | `home_view.dart` | Clay clock |
| Save template icon | `icon_bookmark.png` | 40 | `template_builder_dialog.dart` | Clay bookmark ribbon, gold |
| Toast icons | `toast_check.png`, `toast_error.png` | 28 | `clay_toast.dart` | Clay check in sage, clay cross in coral |
| 404 / empty gallery | `empty_gallery.png` | 240 | `home_view.dart` when no templates | Three empty clay cards |
| Logo re‑render (optional) | `mockuply_logo_3d.png` | 512 | `brand_logo.dart`, favicon, web icons | Re‑render the existing leaf with the shared material so it matches the new icons exactly. The current PNG is already very close |

### D.3 Textures (optional, small)

| Asset | File | Notes |
|---|---|---|
| Paper grain | `grain_tile.png` | 256×256 tile, 2 % opacity over `sand`. Bake from a noise texture, greyscale, seamless. Use `ImageRepeat.repeat` in `ambient_background.dart`. Skip if it costs frame rate on the canvas |

### D.4 Export checklist for every render

1. Film → Transparent on. Output PNG, RGBA, 16‑bit, compression 50 %.
2. Resolution 200 % of the display size listed above.
3. Render, then `Image → Save As`. Check the alpha edge has no dark fringe (set Alpha to Premultiplied in the compositor if it does).
4. Drop the file in `assets/clay/`, run `flutter pub get` after editing `pubspec.yaml`.
5. In Flutter, load with `Image.asset(..., filterQuality: FilterQuality.medium)` and give it an explicit `width`/`height` equal to the display size.

---

## Part E · Implementation order

Work in this order so the app never looks half‑finished for long. Each step is one commit on `feat/claymorphism-redesign`.

1. **Tokens and painter.** `app_colors.dart`, `app_dimensions.dart`, `app_theme.dart`, `clay_decoration.dart`, `clay_container.dart`. Keep `glass_container.dart` for one commit as a thin wrapper around `ClayContainer` so nothing breaks, then delete it.
2. **Component kit.** Everything in A.4 under `lib/widgets/clay/`. Build a throwaway `ClayGallery` screen (reachable via a hidden route) that shows every component in every state, to tune `depth`, `lift` and alpha values once.
3. **Home page.** Navbar, hero, template cards, banner, footer. Delete the home chips. Apply C.2 copy. Hero uses a placeholder box until the Blender render exists.
4. **Editor shell.** Navbar, action rail, mode bar, zoom bar, inspector panel frame, layers list. Delete the editor chips.
5. **Inspector panels.** Text, frame, image, screen, background.
6. **Workspace chrome.** Tabs, store headers, selected card treatment, popovers, canvas handles.
7. **Dialogs and toasts.** Export, template builder, font picker, colour picker, every `SnackBar` → `ClayToast`.
8. **Blender assets.** Replace placeholders as renders land. Rail icons last, since Material icons work fine until then.
9. **Motion.** Part F. Springs on the component kit first (they are built into `ClayButton`, `ClaySegmented`, `ClayToggle` from step 2, so this step tunes them), then screen‑level transitions, Edit ↔ Preview first since it is the reference.
10. **Cleanup.** Remove `ambient_background.dart` orbs, the gallery route, the teal spinner colour, the Mocuply/Mokuply/Mockuply naming split. Run `flutter analyze` and `flutter test`. Neither test depends on any UI string or chip, so they stay green throughout.

### Acceptance checklist

- No `BackdropFilter` anywhere in `lib/`.
- No `Border.all` on a surface in the chrome (borders only remain on canvas selection handles and the phone frames).
- No static pill/chip: `grep -rn "borderRadius: BorderRadius.circular(AppDimensions.radiusXl)" lib/views` returns only interactive controls.
- No exclamation mark in any user‑facing string.
- Every raised control sinks on press (visible in the gallery screen).
- Selected = gold, action = green, danger = coral, everywhere.
- Exported PNGs are byte‑identical before and after (run the export on the same template and diff).
- Motion checklist in F.8 passes.

---

## Part F · Motion

The target feel is the new iOS and macOS: nothing eases, everything **springs**. Controls are physical objects with mass. A tap squashes them, letting go makes them bounce back, a moving selection stretches like a liquid blob toward where it is going and then settles. Animations are interruptible (a second tap mid‑animation redirects, never restarts) and every panel arrives with a tiny stagger so the screen feels assembled, not switched on.

### F.1 Why not GSAP

GSAP animates DOM nodes and CSS properties. Flutter web renders the entire app into one `<canvas>` (CanvasKit or skwasm), so there are no DOM nodes for GSAP to find. Flutter's own engine has what we need and it is already spring‑based:

| GSAP concept | Flutter equivalent |
|---|---|
| `gsap.to(el, {duration, ease})` | `AnimationController` + `Curve`, or an implicit `Animated*` widget |
| `ease: "elastic.out"` / `"back.out"` | `SpringSimulation` with `SpringDescription` (real physics, interruptible). `Curves.elasticOut` exists but is not interruptible, so avoid it on controls |
| `gsap.timeline().stagger` | `flutter_animate` package: `.animate().fadeIn().slideY()` with `delay` per index, or `interval` on one controller |
| `gsap.matchMedia("(prefers-reduced-motion)")` | `MediaQuery.disableAnimationsOf(context)` |
| `FLIP` layout animations | `Hero`, `AnimatedSize`, `AnimatedPositioned`, `SliverAnimatedList`, `reorderables` |

The one place GSAP (or plain CSS) is legitimately useful: the **HTML splash** in `web/index.html` shown before Flutter boots. There is none today; the user sees a blank sand page for one to three seconds. Add a centred clay leaf (the logo PNG) with a gentle bob and a sand background, animated with CSS keyframes or GSAP, and remove it from the DOM when Flutter's first frame renders (`flutter_bootstrap.js` → `onEntrypointLoaded` → after `runApp`, call `document.getElementById('splash').remove()` through `dart:js_interop`). GSAP adds 70 KB for a bob; prefer CSS unless the splash grows.

### F.2 Dependencies and core file

`pubspec.yaml`:

```yaml
flutter_animate: ^4.5.0   # declarative chains, stagger, shimmer
```

Create `lib/core/motion/clay_motion.dart`:

```dart
/// Spring presets. stiffness / damping / mass. Use these, never raw numbers.
class ClaySprings {
  static const snappy  = SpringDescription(mass: 1, stiffness: 520, damping: 32); // press, hover, toggles
  static const bouncy  = SpringDescription(mass: 1, stiffness: 300, damping: 18); // release overshoot, pucks, dialogs
  static const liquid  = SpringDescription(mass: 1, stiffness: 180, damping: 14); // leading edge of a stretching blob
  static const gentle  = SpringDescription(mass: 1, stiffness: 160, damping: 24); // panels sliding in, page transitions
}

class ClayDurations {
  static const press    = Duration(milliseconds: 90);
  static const hover    = Duration(milliseconds: 140);
  static const stagger  = Duration(milliseconds: 35);
  static const toast    = Duration(seconds: 3);
}

/// Drives an AnimationController with a spring instead of a curve. Interruptible:
/// calling again mid-flight starts from the current value and velocity.
extension SpringTo on AnimationController {
  TickerFuture springTo(double target, {SpringDescription spring = ClaySprings.snappy}) {
    final sim = SpringSimulation(spring, value, target, velocity);
    return animateWith(sim);
  }
}
```

Every animated clay control owns an unbounded `AnimationController` (`lowerBound: -1, upperBound: 2`) so springs can overshoot, and calls `springTo` on state changes. Nothing uses `duration` + `forward()` on an interactive element.

### F.3 Reduced motion

Wrap the app in a `ClayMotionScope` that reads `MediaQuery.disableAnimations` and exposes `motion.enabled`. When disabled: springs become `snappy` with damping 60 (no overshoot), stagger is 0, scale effects are off, crossfades stay. Reduced motion also follows the OS setting on macOS and iOS through the browser.

### F.4 Per component motion spec

| Component | Trigger | Motion |
|---|---|---|
| `ClayButton` | pointer down | Scale → 0.96, `lift` 18 → 4, inner shadows swap (sunken), 90 ms, `snappy` |
| | pointer up | Scale springs to 1.0 with `bouncy` (visible overshoot to ~1.03), lift springs back. If released outside, same spring, no `onPressed` |
| | hover | `lift` +6, scale 1.02, `hover` duration |
| | busy (export) | The label crossfades to the progress text; a `shimmer` (flutter_animate) sweeps the clay surface once per second |
| `ClayIconButton` | press / hover | Same as button. If the icon is a Blender clay icon, add a ±6° rotate wobble on hover (`bouncy`), the way iOS app icons jiggle |
| `ClaySegmented` | tap option | The puck is the liquid blob. Two springs: the edge facing the target moves with `liquid` (fast, soft), the trailing edge with `snappy`. The puck visibly stretches, then catches up and settles. Labels crossfade colour over the last 40 %. The track gets a 2 % darker tint while the puck moves |
| `ClayToggle` | tap | Knob squashes to 1.25× wide, 0.85× tall while travelling, springs to round with `bouncy`. Track colour `clayDeep` ↔ `primary` crossfades over the travel. Same two‑edge stretch as the puck |
| `ClaySlider` | grab | Knob scales 1.0 → 1.3 with `snappy`; a value bubble springs up above the knob (scale from 0.6, `bouncy`) and follows it; release shrinks both. The filled track fills with the knob, no lag |
| `ClayTile` (layers, presets, styles, fonts) | select | Tile raises from flat to `lift` 10 with `bouncy`; previous selection lowers with `snappy`. Rows shift to make room with `AnimatedSize` |
| `ClayCard` (templates) | hover | `lift` +8, scale 1.015, `gentle`. The inner preview phones tilt 2° in the hover direction (parallax from pointer position) |
| | tap "Use template" | Card scales to 0.97 then the page transitions (F.5) |
| `ClayField` | focus | Well deepens (`depth` 6 → 9), label slides up 2 px and tints `primary`, `snappy` |
| `ClayDropdown` / `ClayPopover` | open | Scale from 0.9 at the anchor corner, fade in, `bouncy`. Items stagger in 25 ms apart |
| | close | Scale to 0.95 and fade, 120 ms, `snappy`, no bounce |
| `ClayDialog` | open | Barrier fades 200 ms. Panel scales 0.92 → 1.0 and rises 24 px with `bouncy`. Contents stagger (header, then each card) with `ClayDurations.stagger` |
| | close | Scale to 0.96, fade, 140 ms |
| `ClayToast` | show | Slides up from the bottom edge with `bouncy`, icon pops in after 80 ms. Auto dismiss after 3 s by sliding down. Swipe down dismisses |
| Colour knob | tap | Knob squashes, picker dialog opens from the knob's position (scale origin at the knob) |

### F.5 Screen level motion

| Moment | Motion |
|---|---|
| App start | Panels do not pop in together. Order with `ClayDurations.stagger` between each: navbar slides down 16 px and fades; action rail slides in from the left; inspector from the right; mode bar and zoom bar rise from the bottom. All `gentle`. Rail buttons then stagger in top to bottom |
| Home → Editor | The clicked template card scales to 0.97, then the home content fades and slides up 24 px while the editor panels assemble (above). Brand logo tile is a `Hero` between the two navbars so it glides to its new position |
| Editor → Home | Reverse: panels leave in the direction they came from, then home content rises in |
| Edit ↔ Preview (`EditorModeBar`) | This is the showcase. The four panels fly off screen in their own directions with `gentle` and 35 ms stagger (rail left, inspector right, navbar up, zoom bar down), the canvas zooms to fit with the `InteractiveViewer` matrix animated by `gentle` (replace the instant `_transformationController.value =` in `editor_view.dart` with a `Matrix4Tween` driven by a spring), and the selected card's gold underline fades. Preview → Edit brings them back in reverse order. The mode bar puck itself does the liquid stretch |
| Select screen (tab or card) | The gold underline bar is one widget that slides between tabs (`AnimatedPositioned` with `bouncy`), stretching while it moves. The lifted card shadow springs; the previous card settles |
| Add screen | The new tab and card grow in from width 0 with `bouncy` (`AnimatedSize`) and the strip shifts; the new tab gets a one‑time 4° wobble |
| Delete screen | Card scales to 0.9 and fades, neighbours close the gap with `gentle` |
| Reorder screen (menu left/right) | Cards swap with `AnimatedPositioned`, `bouncy` |
| Select element on canvas | Gold outline draws in (stroke dash offset 0 → 1, 180 ms). Corner handles pop in with 20 ms stagger (scale from 0, `bouncy`); rotate handle last. Deselect: all handles scale out together, 100 ms |
| Drag on canvas | Element lifts: its shadow spreads by 30 % on pointer down (`snappy`) and settles on drop with `bouncy`. Snap to the centre guide gives a 1‑frame 1.01 scale tick so the snap is felt |
| Upload image | The frame flashes: screenshot fades in over 220 ms behind the glass of the phone, and the frame does a single `bouncy` scale 1.0 → 1.03 → 1.0 |
| Export | Progress bar fills with `gentle`. On completion the Download button morphs: label crossfades to a check, the button does a `bouncy` pulse, then the toast slides up |
| Inspector content change | Old body fades out and slides down 8 px, new body fades in and slides up from 8 px (`AnimatedSwitcher` with a custom transition, 180 ms). Sliders inside then stagger their tracks filling to their values |
| Layers list | Rows animate in order on screen change, 20 ms stagger |

### F.6 Performance rules for web

- Animate **transform and opacity**, never layout, on anything bigger than a button. Panels slide with `Transform.translate` driven by a controller, not with `AnimatedPositioned` (which relayouts the whole stack).
- Never animate `blurRadius` per frame on a panel‑sized shadow. `ClayDecoration` animates `lift` by moving the shadow offset and its opacity, keeping blur constant. Cache the shadow in a `RepaintBoundary` layer per panel.
- The canvas strip already has a `RepaintBoundary` per screen card. Keep panel animations outside the `InteractiveViewer` subtree so the strip never re‑rasterises while chrome moves.
- Use `TickerMode(enabled: false)` on off‑screen panels (collapsed inspector, preview mode) so their controllers stop ticking.
- Test on the `--web-renderer canvaskit` build at 60 fps with Chrome's performance panel. If skwasm is available in the Flutter version, prefer it; springs look identical and it is faster.
- Blender icons are static PNGs; wobbles and pops are transforms on the image. If an icon needs an internal state animation (the toggle knob rolling, the upload tray opening), render a 12 to 16 frame sprite sheet from Blender and play it with a `SpriteSheet` widget, or build it in Rive. Do not ship video or GIF.

### F.7 The wobble (jelly) effect

This is the signature move. A pressed control should not just shrink and grow back; it should **jiggle like jelly** for a few oscillations, the way iOS 26 and macOS Tahoe controls do when tapped, and the way a clay blob would if you poked it. Three ingredients:

**1. Squash and stretch, out of phase.** Scale X and scale Y are two separate springs, not one. On pointer down: `scaleX → 1.12`, `scaleY → 0.88` (volume roughly preserved, so it reads as soft material, not a zoom). On release both spring to 1.0 with `ClaySprings.liquid` (damping 14, which gives three to four visible oscillations), but Y is started **one frame later** than X. The delay keeps them out of phase, so the element visibly wobbles wide/tall/wide/tall instead of pulsing. Same recipe for the segmented puck and the toggle knob while they travel.

**2. Velocity skew.** Anything that moves (puck, knob, slider thumb, dragged canvas element, a panel flying in) gets a skew proportional to its velocity: `skewX = clamp(velocityX * 0.0006, -0.18, 0.18)` radians, applied through `Transform(transform: Matrix4.skewX(...))` about the centre. When it stops, the skew springs back to 0 with `bouncy`, so the object overshoots and wobbles into place like it has mass and a soft body.

**3. Surface wobble (optional, for the hero and big panels).** The clay rrect itself can deform. In `ClayDecoration`, offset each of the four corner control points of the rounded rect path by a small damped sine, driven by the same spring: `corner.dx += amp * sin(t * 2π * 2.2) * e^(-4t)` with `amp` up to 3 px. The outline ripples for about half a second after a tap. Keep it off on tool UI (inspector rows, zoom bar) and on by default on the hero card, dialogs and the navbar.

Build it once as `JellyTransform` in `lib/widgets/clay/jelly_transform.dart`:

```dart
/// Wraps a child and wobbles it. Call [poke] on press, [release] on release,
/// feed [velocity] while dragging. Two unbounded controllers (x, y) plus one
/// for skew; all driven by springTo, so a second poke mid-wobble just
/// redirects the motion.
class JellyTransform extends StatefulWidget {
  final Widget child;
  final double squash;        // 0.12 default: scaleX 1+squash, scaleY 1-squash on poke
  final SpringDescription spring; // ClaySprings.liquid
  final bool surfaceRipple;   // forwards the ripple phase to ClayDecoration
  ...
}
```

Where it goes:

| Control | Wobble |
|---|---|
| `ClayButton`, `ClayIconButton` | Squash on press, jelly release (ingredient 1). Big buttons on the home page also get the surface ripple |
| `ClayToggle` | Knob squash while travelling, velocity skew in the travel direction, jelly settle at the end. The track gets a tiny counter‑squash (1 % ) so it reacts to the knob landing |
| `ClaySegmented` | Puck stretch (liquid blob) plus velocity skew, jelly settle. Tapping the already selected option gives a small poke wobble with no travel |
| `ClaySlider` | Thumb squash on grab, skew with drag velocity, jelly on release. The value bubble wobbles with the thumb |
| `ClayTile` select | A single, gentler poke: squash 0.05 |
| Canvas elements (phone, text, image) | Skew with drag velocity, jelly settle on drop. Amplitude halved because the content inside is the user's work and must stay readable. Never applied to the exported render |
| Panels on Edit ↔ Preview | Skew along the travel axis while flying, jelly settle on arrival |
| Blender rail icons | Hover: rotate wobble ±6°. Press: squash. Both with `liquid` |
| Toasts | Jelly on arrival, then still |
| Hero render on the home page | Idle: slow 4 s float of 6 px plus 1.5° rotate (`gentle` loop). Pointer near: tilts 4° toward the pointer. Click: squash and surface ripple |

Tuning numbers to start from, then adjust in the `ClayGallery` screen:

| Parameter | Value |
|---|---|
| Press squash | 0.12 (X +12 %, Y −12 %) |
| Release spring | stiffness 180, damping 14, mass 1 |
| Phase offset between X and Y | 1 frame (16 ms) |
| Max skew | 0.18 rad (~10°) |
| Skew velocity factor | 0.0006 rad per px/s |
| Surface ripple amplitude | 3 px, frequency 2.2 Hz, decay e^(−4t) |
| Settle time | all springs below 0.5 % amplitude within 600 ms |

Reduced motion turns ingredients 2 and 3 off and reduces the squash to 0.03 with `snappy`, so controls still acknowledge the press without wobbling.

### F.8 Motion checklist

- No `Curves.linear`, `Curves.ease*` or `Curves.elasticOut` on any interactive control. Springs only. Curves are allowed on pure crossfades.
- Every spring animation is interruptible: tapping mid‑animation redirects from current value and velocity.
- Every animated control respects `ClayMotionScope.enabled`.
- The stagger never exceeds 35 ms per item and the longest entrance never exceeds 450 ms total.
- The Edit ↔ Preview transition is the reference: if it feels right, apply the same springs everywhere else.
- Every pressable control wobbles (F.7). Tap a toggle ten times fast: it must never stutter or restart, only redirect.
