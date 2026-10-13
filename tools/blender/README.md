# Blender clay assets

`render_clay_assets.py` builds every claymorphism asset procedurally (no input .blend),
renders them to `assets/clay/<name>.png` at 2x display size, writes the seamless
`grain_tile.png`, and saves the whole scene to `mockuply_clay.blend` (all assets parked
on a grid, both cameras, both lights) for manual tweaking.

Re-render everything (from the repo root, Blender 5.2 LTS, headless EEVEE, about 2 min on CPU):

```
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/render_clay_assets.py
```

Options after `--`: `--only icon_frame,hero_phone_stack` (subset), `--scale 4` (resolution
multiplier for review renders), `--samples 16` (EEVEE samples, default 64), `--out DIR`
(render somewhere else), `--engine CYCLES` (CPU Cycles fallback), `--no-blend`.

Then re-encode the renders for the web (8-bit PNGs at max compression, the hero as lossless
WebP; each output is checked against its source and the script prints the size saved):

```
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/optimize_web_assets.py
```

Notes on how it follows `docs/CLAYMORPHISM_REDESIGN.md` Part D:

- Material, bevel (3 segments, shade smooth), key/fill area lights (400 W 5200 K top-left,
  120 W 7000 K bottom-right), plain sand world at 0.3, transparent film, 16-bit RGBA PNG at
  50 % compression are as specified. Lights are placed relative to the active camera so the
  highlight always comes from the top-left of the frame.
- Thin slabs use a bevel of ~30 % of their thickness instead of 8 % of the smallest
  dimension; 8 % of a 0.16-unit slab is invisible and the soft edge is the whole style.
- Colour management is "Khronos PBR Neutral" rather than AgX/Filmic: both of those lift
  the dark brand greens into olive grey even after base-colour calibration, while PBR
  Neutral keeps mid tones exact and only rolls off highlights. The script also runs a
  calibration pass (renders a strip of flat token slabs, reads the pixels back, corrects
  each base colour) so every token lands within about 10/255 of its hex. AgX is the
  fallback if the transform is missing.
- The icon camera is orthographic at the classic 54.7° X / 45° Z three-quarter view (a few
  assets override the elevation); the hero uses a 50 mm perspective camera with a 3° roll.
