"""Re-encode the rendered clay assets for the web.

Blender renders 16-bit PNGs, but browsers decode every image to 8 bits per
channel, so the extra depth only costs download time. This script rewrites
each `assets/clay/*.png` as an 8-bit PNG at maximum compression, writes the
large hero render as WebP, and checks every output against its source
(max per-channel difference, in 8-bit steps, on visible pixels).

Run from the repo root after `render_clay_assets.py`:

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/optimize_web_assets.py

Options after `--`: `--dry-run` (write to a temp folder and only report).
"""

import os
import sys
import tempfile

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
CLAY = os.path.join(os.path.dirname(os.path.dirname(HERE)), "assets", "clay")

# Too large as a PNG: shipped as WebP instead (quality per file).
WEBP = {"hero_phone_stack": 100}  # 100 = lossless WebP

# Source renders that are not shipped to the browser and are left alone.
SKIP = {"mockuply_logo_3d"}


def _args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    return "--dry-run" in argv


def _setup_scene():
    scene = bpy.context.scene
    # Pass colours through untouched: sRGB in, sRGB out.
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    return scene


def _save(scene, img, path, webp_quality=None):
    s = scene.render.image_settings
    if webp_quality is None:
        s.file_format = "PNG"
        s.color_depth = "8"
        s.compression = 100
    else:
        s.file_format = "WEBP"
        s.quality = webp_quality
    s.color_mode = "RGBA"
    img.save_render(path, scene=scene)


def _max_diff(a_path, b_path):
    """Largest channel difference (0-255) over pixels that are not fully transparent."""
    a = bpy.data.images.load(a_path, check_existing=False)
    b = bpy.data.images.load(b_path, check_existing=False)
    for img in (a, b):
        img.colorspace_settings.name = "Non-Color"  # compare stored values, not colours
    pa, pb = list(a.pixels), list(b.pixels)
    worst = 0.0
    for i in range(0, len(pa), 4):
        if pa[i + 3] < 1 / 255 and pb[i + 3] < 1 / 255:
            continue
        for c in range(4):
            d = abs(pa[i + c] - pb[i + c])
            if d > worst:
                worst = d
    bpy.data.images.remove(a)
    bpy.data.images.remove(b)
    return round(worst * 255, 2)


def main():
    dry_run = _args()
    scene = _setup_scene()
    out_dir = tempfile.mkdtemp(prefix="clay_web_") if dry_run else CLAY
    total_before = total_after = 0

    for name in sorted(os.listdir(CLAY)):
        stem, ext = os.path.splitext(name)
        if ext != ".png" or stem in SKIP:
            continue
        src = os.path.join(CLAY, name)
        before = os.path.getsize(src)
        img = bpy.data.images.load(src, check_existing=False)
        quality = WEBP.get(stem)
        tmp = os.path.join(tempfile.gettempdir(), stem + (".webp" if quality else ".png"))
        _save(scene, img, tmp, quality)
        bpy.data.images.remove(img)

        after = os.path.getsize(tmp)
        diff = _max_diff(src, tmp)
        dest = os.path.join(out_dir, os.path.basename(tmp))
        os.replace(tmp, dest)
        if quality and not dry_run:
            os.remove(src)  # the WebP replaces the PNG
        total_before += before
        total_after += after
        print(f"[web] {name:28s} {before / 1024:8.1f} KB -> {after / 1024:8.1f} KB  max diff {diff}/255")

    print(f"[web] total {total_before / 1024:.0f} KB -> {total_after / 1024:.0f} KB ({out_dir})")


main()
