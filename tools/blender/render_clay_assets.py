"""Procedural claymorphism asset renderer for Mokuply.

Run headless from the repo root:

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/render_clay_assets.py

Everything is built from primitives (no input .blend). Renders land in
assets/clay/<name>.png at 2x the display size, and the whole scene (all assets laid
out on a grid, both cameras, both lights) is saved to tools/blender/mockuply_clay.blend.

Optional CLI flags after "--":
    --only name1,name2   render only these assets (by file stem)
    --scale 0.5          multiply the render resolution (quick previews)
    --samples 32         EEVEE TAA samples (default 64)
    --engine CYCLES      use Cycles instead of EEVEE
    --no-blend           skip saving the .blend file
    --out DIR            write the PNGs somewhere else (review renders)

Written against Blender 5.2 LTS (Principled BSDF v2 input names, EEVEE id 'BLENDER_EEVEE').
"""

import math
import os
import sys
from math import radians

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Vector

# --------------------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------------------

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(REPO, "assets", "clay")
BLEND_PATH = os.path.join(HERE, "mockuply_clay.blend")

# --------------------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------------------


def _parse_args():
    argv = sys.argv
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    opts = {"only": None, "scale": 1.0, "samples": 64, "engine": "BLENDER_EEVEE", "blend": True, "out": None}
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--only":
            opts["only"] = set(args[i + 1].split(","))
            i += 2
        elif a == "--scale":
            opts["scale"] = float(args[i + 1])
            i += 2
        elif a == "--samples":
            opts["samples"] = int(args[i + 1])
            i += 2
        elif a == "--engine":
            opts["engine"] = args[i + 1]
            i += 2
        elif a == "--no-blend":
            opts["blend"] = False
            i += 1
        elif a == "--out":
            opts["out"] = os.path.abspath(args[i + 1])
            i += 2
        else:
            i += 1
    return opts


OPTS = _parse_args()
if OPTS["out"]:
    OUT_DIR = OPTS["out"]

# --------------------------------------------------------------------------------------
# Colour tokens (sRGB hex -> linear RGBA)
# --------------------------------------------------------------------------------------

TOKENS_HEX = {
    "sand": "EFE8D6",
    "clay": "FBF6EA",
    "clayDeep": "F1EAD8",
    "primary": "2D6A4F",
    "primaryDeep": "1A4731",
    "primaryLight": "52B788",
    "mint": "CDE7D6",
    "gold": "E8C464",
    "goldDeep": "C9A440",
    "goldLight": "FFE79A",
    "butter": "FFF0C2",
    "coral": "F08A7E",
    "coralDeep": "D9675B",
    "sage": "8FBF9F",
}


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_linear(h):
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return (srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b), 1.0)


# The view transform (AgX) and the lighting change the colour a lit flat face ends up with
# on screen. The spec says to land near the token hex by adjusting the base colour, not
# the lights, so calibrate_tokens() renders a strip of flat slabs, reads the pixels back
# and iteratively corrects each token's base colour. The result is stored here as linear
# RGB per token; before calibration it is simply the linear token colour.
TOKEN_BASE = {}


def token_linear(name):
    if name in TOKEN_BASE:
        r, g, b = TOKEN_BASE[name]
        return (r, g, b, 1.0)
    return hex_to_linear(TOKENS_HEX[name])


def linear_to_srgb(v):
    v = max(0.0, min(1.0, v))
    return v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055


def calibrate_tokens(iterations=4, verbose=True):
    """Renders every token as a small flat slab facing the icon camera, measures the
    rendered colour and nudges the base colour so the lit face matches the hex token."""
    scene = bpy.context.scene
    tokens = list(TOKENS_HEX.keys())
    targets = {t: hex_to_linear(TOKENS_HEX[t])[:3] for t in tokens}
    for t in tokens:
        TOKEN_BASE[t] = list(targets[t])
    tmp_path = os.path.join(bpy.app.tempdir or HERE, "clay_calibration.png")
    n = len(tokens)
    old_samples = scene.eevee.taa_render_samples
    scene.eevee.taa_render_samples = min(old_samples, 16)
    for it in range(iterations):
        _MATERIALS.clear()
        coll = bpy.data.collections.new("Calibration")
        scene.collection.children.link(coll)
        global _current_collection
        _current_collection = coll
        step = 0.24
        for i, t in enumerate(tokens):
            slab(t, 0.2, 0.2, 0.05, t, radius=0.01, location=((i - (n - 1) / 2) * step, 0, 0))
        _current_collection = None
        bpy.context.view_layer.update()
        res_x, res_y = n * 40, 40
        scene.render.resolution_x, scene.render.resolution_y = res_x, res_y
        cam = bpy.data.objects["IconCamera"]
        centre = frame_ortho(cam, all_mesh_objects(coll), res_x, res_y, fill=1.0, rx=0, rz=0)
        scene.camera = cam
        place_lights(cam, bpy.data.objects["KeyLight"], bpy.data.objects["FillLight"], target=centre,
                     distance=LIGHT_DISTANCE)
        scene.render.filepath = tmp_path
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(tmp_path)
        w, h = img.size
        px = np.array(img.pixels[:], dtype=np.float64).reshape(h, w, 4)
        bpy.data.images.remove(img)
        max_err = 0.0
        for i, t in enumerate(tokens):
            cx = int((i + 0.5) / n * w)
            got = px[h // 2 - 3:h // 2 + 4, cx - 3:cx + 4, :3].mean(axis=(0, 1))
            want = targets[t]
            base = TOKEN_BASE[t]
            for k in range(3):
                ratio = want[k] / max(got[k], 1e-4)
                ratio = max(0.5, min(2.0, ratio))
                base[k] = max(0.0, min(1.0, base[k] * ratio))
            err = max(abs(linear_to_srgb(got[k]) - linear_to_srgb(want[k])) for k in range(3)) * 255
            max_err = max(max_err, err)
            if verbose and it == iterations - 1:
                got_hex = "".join(f"{int(round(linear_to_srgb(c) * 255)):02X}" for c in got)
                print(f"[clay]   {t:12s} want {TOKENS_HEX[t]}  got {got_hex}")
        if verbose:
            print(f"[clay] calibration pass {it + 1}: max channel error {max_err:.1f}/255")
        # remove the calibration objects
        for o in list(coll.objects):
            mesh = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.meshes.remove(mesh)
        bpy.data.collections.remove(coll)
        bpy.context.view_layer.update()
    _MATERIALS.clear()
    scene.eevee.taa_render_samples = old_samples
    if os.path.exists(tmp_path):
        try:
            os.remove(tmp_path)
        except OSError:
            pass


# --------------------------------------------------------------------------------------
# Scene setup
# --------------------------------------------------------------------------------------

ASSET_COLLECTIONS = []  # (collection, grid offset) kept for the .blend layout
_MATERIALS = {}

# Lights sit this far from the composition centre (the spec gives powers and sizes, not
# distances) and the scene exposure lifts the AgX curve so cream reads as cream.
LIGHT_DISTANCE = 4.0
EXPOSURE = 0.0
# Colour management. The spec asks for AgX/Filmic "Medium Contrast", but both lift and
# desaturate the dark brand greens into olive grey (primaryDeep #1A4731 came out #404B3B
# even after base-colour calibration). Khronos PBR Neutral keeps mid tones exact and only
# rolls off the highlights, which is what the clay look needs; every token lands within
# ~10/255 of its hex after calibration. AgX is the fallback if the transform is missing.
VIEW_TRANSFORM = 'Khronos PBR Neutral'
VIEW_LOOKS = ('None',)
FALLBACK_VIEW_TRANSFORM = 'AgX'
FALLBACK_LOOKS = ('AgX - Base Contrast', 'AgX - Medium Contrast', 'None')


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "ClayAssets"
    scene.unit_settings.system = "METRIC"

    # Engine
    engine = OPTS["engine"]
    try:
        scene.render.engine = engine
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    if scene.render.engine == "BLENDER_EEVEE":
        ev = scene.eevee
        ev.taa_render_samples = OPTS["samples"]
        ev.use_shadows = True
        ev.shadow_ray_count = 4
        ev.shadow_step_count = 8
        ev.use_raytracing = False  # no visible reflections, matte clay only
        ev.use_fast_gi = False
    else:
        cy = scene.cycles
        cy.device = "CPU"
        cy.samples = max(32, OPTS["samples"])
        cy.use_denoising = True
        cy.max_bounces = 4
        cy.caustics_reflective = False
        cy.caustics_refractive = False

    # Film / output
    scene.render.film_transparent = True
    scene.render.dither_intensity = 1.0
    img = scene.render.image_settings
    img.file_format = "PNG"
    img.color_mode = "RGBA"
    img.color_depth = "16"
    img.compression = 50
    img.color_management = "FOLLOW_SCENE"

    # Colour management: AgX, medium ("Base") contrast
    looks = VIEW_LOOKS
    try:
        scene.view_settings.view_transform = VIEW_TRANSFORM
    except TypeError:
        scene.view_settings.view_transform = FALLBACK_VIEW_TRANSFORM
        looks = FALLBACK_LOOKS
    for look in looks:
        try:
            scene.view_settings.look = look
            break
        except TypeError:
            continue
    scene.view_settings.exposure = EXPOSURE
    scene.view_settings.gamma = 1.0
    scene.display_settings.display_device = "sRGB"

    # World: plain sand colour, 0.3 strength, no HDRI
    world = bpy.data.worlds.new("ClayWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = hex_to_linear(TOKENS_HEX["sand"])
    bg.inputs["Strength"].default_value = 0.3
    scene.world = world

    _MATERIALS.clear()
    ASSET_COLLECTIONS.clear()


def make_area_light(name, power, size, kelvin):
    data = bpy.data.lights.new(name, type="AREA")
    data.energy = power
    data.size = size
    data.shape = "SQUARE"
    if hasattr(data, "use_temperature"):
        data.use_temperature = True
        data.temperature = kelvin
    else:  # older API: approximate blackbody tint
        data.color = (1.0, 0.93, 0.85) if kelvin < 6000 else (0.87, 0.91, 1.0)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def aim(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_lights_and_cameras():
    """Creates both cameras and both lights once. Lights are placed relative to the
    icon camera so the key light is top-left of the frame and the fill bottom-right."""
    scene = bpy.context.scene

    cam_iso_data = bpy.data.cameras.new("IconCamera")
    cam_iso_data.type = "ORTHO"
    cam_iso_data.ortho_scale = 2.2
    cam_iso_data.clip_start = 0.01
    cam_iso_data.clip_end = 200
    cam_iso = bpy.data.objects.new("IconCamera", cam_iso_data)
    scene.collection.objects.link(cam_iso)

    cam_persp_data = bpy.data.cameras.new("HeroCamera")
    cam_persp_data.type = "PERSP"
    cam_persp_data.lens = 50
    cam_persp_data.sensor_width = 36
    cam_persp_data.clip_start = 0.01
    cam_persp_data.clip_end = 200
    cam_persp = bpy.data.objects.new("HeroCamera", cam_persp_data)
    scene.collection.objects.link(cam_persp)

    key = make_area_light("KeyLight", 400, 3.0, 5200)
    fill = make_area_light("FillLight", 120, 2.0, 7000)
    return cam_iso, cam_persp, key, fill


def place_lights(cam, key, fill, target=(0, 0, 0), distance=7.0):
    """Key light top-left of the camera frame, fill bottom-right."""
    rot = cam.matrix_world.to_3x3()
    t = Vector(target)
    # camera local: +X right, +Y up, +Z backwards (towards the viewer)
    key.location = t + rot @ (Vector((-0.7, 0.85, 0.9)).normalized() * distance)
    fill.location = t + rot @ (Vector((0.8, -0.55, 0.9)).normalized() * distance)
    aim(key, t)
    aim(fill, t)


# --------------------------------------------------------------------------------------
# Materials & mesh helpers
# --------------------------------------------------------------------------------------


def clay_material(token, sss_scale=0.05):
    key = (token, round(sss_scale, 3))
    if key in _MATERIALS:
        return _MATERIALS[key]
    mat = bpy.data.materials.new(f"Clay_{token}_{round(sss_scale, 3)}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = token_linear(token)
    bsdf.inputs["Roughness"].default_value = 0.65
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.3
    bsdf.inputs["Subsurface Weight"].default_value = 0.08
    bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.6, 0.4)
    bsdf.inputs["Subsurface Scale"].default_value = sss_scale
    bsdf.inputs["Sheen Weight"].default_value = 0.1
    bsdf.inputs["Coat Weight"].default_value = 0.0
    _MATERIALS[key] = mat
    return mat


_current_collection = None


def _link(obj):
    coll = _current_collection or bpy.context.scene.collection
    coll.objects.link(obj)
    return obj


def _select_only(obj):
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def finish(obj, token, bevel_frac=0.08, bevel=True, segments=3, angle=30.0, sss=None):
    """Assigns the clay material, applies scale, adds the Bevel modifier and Shade Smooth."""
    _select_only(obj)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    dims = [d for d in obj.dimensions if d > 1e-6]
    smallest = min(dims) if dims else 0.1
    mat = clay_material(token, sss if sss is not None else max(0.01, 0.12 * smallest))
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Bevel", type="BEVEL")
        mod.segments = segments
        mod.width = bevel_frac * smallest
        mod.limit_method = "ANGLE"
        mod.angle_limit = radians(angle)
        mod.use_clamp_overlap = True
        mod.harden_normals = True
        mod.miter_outer = "MITER_SHARP"  # MITER_ARC throws vertices to infinity on boolean output
    bpy.ops.object.shade_smooth()
    return obj


def new_mesh_object(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    _link(obj)
    return obj


def _rounded_rect_points(w, h, r, seg=8):
    r = min(r, w / 2 - 1e-4, h / 2 - 1e-4)
    pts = []
    corners = [(w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90),
               (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)]
    for cx, cy, start in corners:
        for i in range(seg + 1):
            a = radians(start + 90 * i / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def extrude_profile(name, pts2d, thickness, token, bevel_frac=0.08, bevel=True, segments=3):
    """Builds a solid from a closed 2D outline (XY) extruded along +Z, bottom at z=0."""
    bm = bmesh.new()
    verts = [bm.verts.new((x, y, 0.0)) for x, y in pts2d]
    bm.faces.new(verts)
    bm.faces.ensure_lookup_table()
    res = bmesh.ops.extrude_face_region(bm, geom=[bm.faces[0]])
    top_verts = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, 0, thickness), verts=top_verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = new_mesh_object(name, bm)
    return finish(obj, token, bevel_frac=bevel_frac, bevel=bevel, segments=segments)


def slab(name, w, h, t, token, radius=None, bevel_frac=0.3, location=(0, 0, 0), rotation=(0, 0, 0),
         segments=3):
    """Rounded slab: w (X) x h (Y) x t (Z thickness), centred, with rounded corners."""
    if radius is None:
        radius = min(w, h) * 0.18
    pts = _rounded_rect_points(w, h, radius)
    obj = extrude_profile(name, pts, t, token, bevel_frac=bevel_frac, segments=segments)
    # centre on Z
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.translate(bm, vec=(0, 0, -t / 2), verts=bm.verts[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return obj


def box(name, size, token, location=(0, 0, 0), rotation=(0, 0, 0), bevel_frac=0.3):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.scale = size
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel_frac=bevel_frac)


def cylinder(name, radius, depth, token, location=(0, 0, 0), rotation=(0, 0, 0), verts=48, bevel_frac=0.08):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel_frac=bevel_frac)


def sphere(name, radius, token, location=(0, 0, 0), scale=(1, 1, 1), rotation=(0, 0, 0), segments=48):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=max(8, segments // 2), radius=radius)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    finish(obj, token, bevel=False)
    obj.scale = scale
    return obj


def cone(name, radius, depth, token, location=(0, 0, 0), rotation=(0, 0, 0), verts=48):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=radius, radius2=0.0, depth=depth)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel_frac=0.1)


def boolean_cut(obj, cutter, bevel_width=None):
    """Subtracts cutter from obj. bevel_width must stay below the thinnest wall the cut
    leaves behind, otherwise the Bevel modifier produces runaway vertices (and EEVEE's
    shadow pass crashes on them)."""
    mod = obj.modifiers.new("Cut", type="BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    # keep the bevel last in the stack so the cut edges get rounded too
    bevel = obj.modifiers.get("Bevel")
    if bevel is not None:
        if bevel_width is not None:
            bevel.width = bevel_width
        _select_only(obj)
        with bpy.context.temp_override(object=obj):
            bpy.ops.object.modifier_move_to_index(modifier=mod.name, index=0)
    cutter.hide_render = True
    cutter.hide_viewport = True
    cutter.display_type = "WIRE"
    return obj


def leaf_points(length, width, n=24, tip_pow=0.75):
    """Pointed leaf outline along +X (tip at +length/2, stalk at -length/2)."""
    pts = []
    for i in range(n + 1):
        t = i / n
        x = -length / 2 + length * t
        y = width / 2 * math.sin(math.pi * t) ** tip_pow
        pts.append((x, y))
    for i in range(n - 1, 0, -1):
        t = i / n
        x = -length / 2 + length * t
        y = -width / 2 * math.sin(math.pi * t) ** tip_pow
        pts.append((x, y))
    return pts


def leaf(name, length, width, thickness, token="gold", location=(0, 0, 0), rotation=(0, 0, 0), bend=25.0):
    obj = extrude_profile(name, leaf_points(length, width), thickness, token, bevel_frac=0.45, segments=5)
    # centre on z, then add a gentle curl
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.translate(bm, vec=(0, 0, -thickness / 2), verts=bm.verts[:])
    bm.to_mesh(obj.data)
    bm.free()
    if bend:
        sub = obj.modifiers.new("Sub", type="SUBSURF")
        sub.levels = 2
        sub.render_levels = 2
        sub.subdivision_type = "SIMPLE"
        bendmod = obj.modifiers.new("Bend", type="SIMPLE_DEFORM")
        bendmod.deform_method = "BEND"
        bendmod.angle = radians(bend)
        bendmod.deform_axis = "Y"
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return obj


def text_mesh(name, body, token, size=1.0, extrude=0.18, location=(0, 0, 0), rotation=(0, 0, 0)):
    curve = bpy.data.curves.new(name, type="FONT")
    curve.body = body
    curve.size = size
    curve.extrude = extrude / 2
    curve.bevel_depth = extrude * 0.22
    curve.offset = -curve.bevel_depth  # the bevel grows the outline; keep counters open
    curve.bevel_resolution = 3
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.resolution_u = 8
    for font_path in ("C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/verdanab.ttf",
                      "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        if os.path.exists(font_path):
            curve.font = bpy.data.fonts.load(font_path)
            break
    obj = bpy.data.objects.new(name, curve)
    _link(obj)
    _select_only(obj)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.active_object
    obj.name = name
    # merge doubles so the shading is clean
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    # the curve bevel already rounded the edges; no modifier bevel needed
    return finish(obj, token, bevel=False)


def arc_tube(name, radius, tube, token, start_deg, end_deg, steps=48):
    """Solid tube swept along a circular arc in the XY plane, with end caps."""
    bm = bmesh.new()
    ring = bmesh.ops.create_circle(bm, cap_ends=True, radius=tube, segments=24)
    # move the profile to (radius, 0, 0), standing in the XZ plane
    bmesh.ops.rotate(bm, verts=bm.verts[:], cent=(0, 0, 0), matrix=Matrix.Rotation(radians(90), 3, "X"))
    bmesh.ops.translate(bm, vec=(radius, 0, 0), verts=bm.verts[:])
    bmesh.ops.rotate(bm, verts=bm.verts[:], cent=(0, 0, 0), matrix=Matrix.Rotation(radians(start_deg), 3, "Z"))
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.spin(bm, geom=geom, cent=(0, 0, 0), axis=(0, 0, 1), angle=radians(end_deg - start_deg),
                   steps=steps, use_duplicate=False)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = new_mesh_object(name, bm)
    return finish(obj, token, bevel=False)


# --------------------------------------------------------------------------------------
# Composite builders
# --------------------------------------------------------------------------------------


def phone(name, w, h, t, body="primary", screen="clay", radius=None, camera_dot=False, location=(0, 0, 0),
          rotation=(0, 0, 0), bezel=0.07):
    """Phone slab standing on XY (face towards +Z) centred at origin; returned as a parent empty."""
    root = bpy.data.objects.new(name, None)
    _link(root)
    if radius is None:
        radius = w * 0.16
    body_obj = slab(name + "_body", w, h, t, body, radius=radius)
    sw, sh = w - 2 * bezel, h - 2 * bezel - (0.06 if camera_dot else 0.0)
    screen_obj = slab(name + "_screen", sw, sh, t * 0.5, screen, radius=max(0.02, radius - bezel),
                      location=(0, -(0.03 if camera_dot else 0.0), t * 0.5))
    parts = [body_obj, screen_obj]
    if camera_dot:
        dot = sphere(name + "_cam", 0.03, "primaryDeep", location=(0, h / 2 - bezel * 0.55, t * 0.5 + 0.015))
        parts.append(dot)
    for p in parts:
        p.parent = root
    root.location = location
    root.rotation_euler = [radians(a) for a in rotation]
    return root


# --------------------------------------------------------------------------------------
# Camera framing
# --------------------------------------------------------------------------------------


def _bbox_points(objs):
    pts = []
    for o in objs:
        if o.type != "MESH" or o.hide_render:
            continue
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    return pts


def all_mesh_objects(coll):
    return [o for o in coll.all_objects if o.type == "MESH" and not o.hide_render]


def frame_ortho(cam, objs, res_x, res_y, fill=0.8, rx=54.7, rz=45.0, target=None):
    cam.rotation_euler = (radians(rx), 0.0, radians(rz))
    bpy.context.view_layer.update()
    rot = cam.rotation_euler.to_matrix()
    inv = rot.inverted()
    pts = _bbox_points(objs)
    local = [inv @ p for p in pts]
    xs = [p.x for p in local]
    ys = [p.y for p in local]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    ext_x, ext_y = max(xs) - min(xs), max(ys) - min(ys)
    aspect = res_y / res_x
    if res_x >= res_y:
        scale = max(ext_x, ext_y / aspect) / fill
    else:
        scale = max(ext_y, ext_x * aspect) / fill
    cam.data.ortho_scale = scale
    centre_local = Vector((cx, cy, 0))
    if target is not None:
        centre_local = inv @ Vector(target)
        centre_local.z = 0
    centre_world = rot @ centre_local
    cam.location = centre_world + rot @ Vector((0, 0, 12.0))
    bpy.context.view_layer.update()
    return centre_world


def frame_persp(cam, objs, res_x, res_y, fill=0.8, rx=68.0, rz=22.0, target=None, roll=0.0):
    cam.rotation_euler = (radians(rx), 0.0, radians(rz))
    bpy.context.view_layer.update()
    rot = cam.rotation_euler.to_matrix()
    inv = rot.inverted()
    pts = _bbox_points(objs)
    local = [inv @ p for p in pts]
    centre_local = Vector(((min(p.x for p in local) + max(p.x for p in local)) / 2,
                           (min(p.y for p in local) + max(p.y for p in local)) / 2,
                           (min(p.z for p in local) + max(p.z for p in local)) / 2))
    if target is not None:
        centre_local = inv @ Vector(target)
    sensor = cam.data.sensor_width
    f = cam.data.lens
    if res_x >= res_y:
        tan_x = sensor / (2 * f)
        tan_y = tan_x * res_y / res_x
    else:
        tan_y = sensor / (2 * f)
        tan_x = tan_y * res_x / res_y
    t_needed = 0.0
    for p in local:
        q = p - centre_local
        t_needed = max(t_needed, abs(q.x) / (tan_x * fill) + q.z, abs(q.y) / (tan_y * fill) + q.z)
    cam.location = rot @ (centre_local + Vector((0, 0, t_needed)))
    if roll:  # slight tilt around the view axis
        cam.rotation_euler = (rot @ Matrix.Rotation(radians(roll), 3, "Z")).to_euler()
    bpy.context.view_layer.update()
    return rot @ centre_local


# --------------------------------------------------------------------------------------
# Rendering driver
# --------------------------------------------------------------------------------------

GRID_STEP = 6.0


def render_asset(name, build_fn, size, camera="iso", fill=0.8, rx=None, rz=None, light_distance=None, roll=0.0):
    """Builds an asset in its own collection, frames it, renders it, then parks it on a grid."""
    global _current_collection
    scene = bpy.context.scene
    if OPTS["only"] and name not in OPTS["only"]:
        return
    coll = bpy.data.collections.new(name)
    scene.collection.children.link(coll)
    _current_collection = coll
    build_fn()
    _current_collection = None
    bpy.context.view_layer.update()

    w, h = size
    res_x = max(8, int(round(w * 2 * OPTS["scale"])))
    res_y = max(8, int(round(h * 2 * OPTS["scale"])))
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y
    scene.render.resolution_percentage = 100

    objs = all_mesh_objects(coll)
    for o in objs:
        if any((not math.isfinite(d)) or d > 50.0 for d in o.dimensions):
            raise RuntimeError(f"[clay] {name}: object {o.name} has runaway bounds {tuple(o.dimensions)} "
                               "(bevel width larger than a wall?)")
    cam_iso = bpy.data.objects["IconCamera"]
    cam_persp = bpy.data.objects["HeroCamera"]
    key, fill_light = bpy.data.objects["KeyLight"], bpy.data.objects["FillLight"]
    if camera == "iso":
        cam = cam_iso
        centre = frame_ortho(cam, objs, res_x, res_y, fill=fill, rx=rx if rx is not None else 54.7,
                             rz=rz if rz is not None else 45.0)
    else:
        cam = cam_persp
        centre = frame_persp(cam, objs, res_x, res_y, fill=fill, rx=rx if rx is not None else 68.0,
                             rz=rz if rz is not None else 22.0, roll=roll)
    scene.camera = cam
    place_lights(cam, key, fill_light, target=centre, distance=light_distance or LIGHT_DISTANCE)
    scene.view_settings.exposure = EXPOSURE

    out = os.path.join(OUT_DIR, name + ".png")
    scene.render.filepath = out
    print(f"[clay] rendering {name} -> {res_x}x{res_y}")
    bpy.ops.render.render(write_still=True)
    print(f"[clay] wrote {out}")

    # Park the asset on the grid and hide it from later renders
    idx = len(ASSET_COLLECTIONS)
    offset = Vector(((idx % 6) * GRID_STEP, -(idx // 6) * GRID_STEP, 0)) + Vector((0, 0, 0))
    offset += Vector((0, -GRID_STEP * 2, 0))  # keep the render area at the origin free
    for o in coll.objects:
        if o.parent is None:
            o.location = o.location + offset
    coll.hide_render = True
    ASSET_COLLECTIONS.append((coll, offset))


# --------------------------------------------------------------------------------------
# Asset definitions
# --------------------------------------------------------------------------------------


def build_hero():
    # Two phones leaning on each other, tilted back so the top-left key light rakes them
    phone("iphone", 0.9, 1.85, 0.16, body="primary", screen="clay", radius=0.16,
          location=(-0.5, 0.2, 0.9), rotation=(70, 0, -12))
    phone("galaxy", 0.85, 1.8, 0.16, body="primaryDeep", screen="clay", radius=0.2, camera_dot=True,
          location=(0.6, -0.2, 0.86), rotation=(70, 0, 16))
    # Floating screenshot cards: two behind and above, one in front and low
    card_a = slab("card_a", 0.9, 1.2, 0.08, "clay", radius=0.12, location=(-1.55, 0.9, 1.5), rotation=(62, 10, -25))
    slab("card_b", 0.85, 1.1, 0.08, "clayDeep", radius=0.12, location=(1.6, 0.8, 1.45), rotation=(60, 0, -10))
    card_c = slab("card_c", 0.72, 0.92, 0.08, "clay", radius=0.1, location=(1.4, -0.6, 0.15), rotation=(55, 0, 30))
    # Gold leaf resting on the front card (parented so it sits flat on the card face)
    lf = leaf("hero_leaf", 0.5, 0.22, 0.07, token="gold", location=(0.02, 0.0, 0.07), rotation=(0, 0, -28), bend=25)
    lf.parent = card_c
    lf2 = leaf("hero_leaf2", 0.36, 0.16, 0.06, token="gold", location=(0.08, 0.18, 0.07), rotation=(0, 0, 35), bend=20)
    lf2.parent = card_a


def build_icon_frame():
    phone("frame", 0.9, 1.7, 0.18, body="primary", screen="clay", rotation=(80, 0, -8), location=(0, 0, 0.85))


def build_icon_text():
    text_mesh("A", "A", "clay", size=1.15, extrude=0.26, location=(-0.42, 0, 0), rotation=(80, 0, 0))
    text_mesh("a", "a", "gold", size=1.15, extrude=0.26, location=(0.42, 0, -0.12), rotation=(80, 0, 0))


def build_icon_image():
    root_rot = (80, 0, -8)
    frame = slab("img_frame", 1.6, 1.3, 0.18, "clay", radius=0.22, rotation=root_rot)
    cutter = slab("img_cutter", 1.2, 0.9, 0.4, "clay", radius=0.1, rotation=root_rot)
    boolean_cut(frame, cutter, bevel_width=0.04)
    back = slab("img_back", 1.25, 0.95, 0.06, "mint", radius=0.1, rotation=root_rot)
    # inside: gold sun and a flattened green hill, parented to the backing plate
    sun = sphere("img_sun", 0.13, "gold", location=(-0.3, 0.18, 0.08))
    hill = sphere("img_hill", 0.3, "primary", location=(0.14, -0.3, 0.03), scale=(1.4, 0.85, 0.35))
    sun.parent = back
    hill.parent = back
    return [frame, back, sun, hill]


def build_icon_upload():
    tray = slab("tray", 1.5, 1.0, 0.55, "primary", radius=0.16, location=(0, 0, 0.27))
    cutter = slab("tray_cut", 1.3, 0.8, 0.6, "primary", radius=0.1, location=(0, 0, 0.45))
    boolean_cut(tray, cutter, bevel_width=0.03)
    cylinder("arrow_shaft", 0.11, 0.8, "clay", location=(0, 0, 0.72))
    cone("arrow_head", 0.3, 0.42, "clay", location=(0, 0, 1.3))


def build_icon_layout():
    slab("bar1", 1.5, 0.42, 0.18, "clay", radius=0.12, location=(-0.1, 0.55, 0.0))
    slab("bar2", 1.5, 0.42, 0.18, "primary", radius=0.12, location=(0.05, 0.0, 0.18))
    slab("bar3", 1.5, 0.42, 0.18, "gold", radius=0.12, location=(0.2, -0.55, 0.36))


def build_icon_backdrop():
    disc = cylinder("palette", 0.85, 0.18, "clay", verts=64)
    hole = cylinder("palette_hole", 0.2, 0.5, "clay", location=(0.42, -0.32, 0))
    boolean_cut(disc, hole, bevel_width=0.03)
    sphere("dot_green", 0.16, "primary", location=(-0.4, 0.28, 0.13))
    sphere("dot_gold", 0.16, "gold", location=(0.05, 0.5, 0.13))
    sphere("dot_coral", 0.16, "coral", location=(-0.45, -0.25, 0.13))


def build_icon_rows_both():
    slab("row_a", 0.75, 1.4, 0.18, "primary", radius=0.12, location=(-0.46, 0, 0))
    slab("row_b", 0.75, 1.4, 0.18, "primaryDeep", radius=0.12, location=(0.46, 0, 0))


def build_icon_rows_one():
    slab("row_one", 0.9, 1.4, 0.18, "primary", radius=0.12)


def build_icon_reset():
    arc_tube("reset_arc", 0.6, 0.13, "primary", start_deg=60, end_deg=360)
    # arrowhead at the arc end (angle 60), pointing along the tangent (clockwise sweep)
    a = radians(60)
    end = Vector((0.6 * math.cos(a), 0.6 * math.sin(a), 0))
    tangent = Vector((math.sin(a), -math.cos(a), 0))  # direction of decreasing angle
    head = cone("reset_head", 0.3, 0.42, "primary", location=end + tangent * 0.12)
    head.rotation_euler = tangent.to_track_quat("Z", "Y").to_euler()


def build_tpl_phone():
    phone("tpl", 0.9, 1.85, 0.16, body="clay", screen="clayDeep", radius=0.16, rotation=(0, 0, 0))


def build_export_both():
    base = slab("box", 1.7, 1.7, 0.5, "clay", radius=0.3, location=(0, 0, 0.25))
    # apple silhouette: sphere with a bite plus a leaf
    apple = sphere("apple", 0.3, "primary", location=(-0.42, 0.05, 0.55), scale=(1.0, 1.0, 0.72))
    bite = sphere("apple_bite", 0.17, "primary", location=(-0.17, 0.08, 0.6))
    boolean_cut(apple, bite)
    leaf("apple_leaf", 0.26, 0.13, 0.08, token="primary", location=(-0.3, 0.3, 0.74), rotation=(55, 0, 35), bend=0)
    # plain rounded rectangle
    slab("droid", 0.6, 0.78, 0.18, "primaryDeep", radius=0.16, location=(0.42, 0.0, 0.55))
    return base


def build_export_apple():
    phone("exp_iphone", 0.9, 1.8, 0.18, body="primary", screen="clay", radius=0.16, rotation=(80, 0, -8),
          location=(0, 0, 0.9))


def build_export_play():
    phone("exp_galaxy", 0.9, 1.8, 0.18, body="primaryDeep", screen="clay", radius=0.24, camera_dot=True,
          rotation=(80, 0, 8), location=(0, 0, 0.9))


def build_empty_frame():
    rot = (78, 0, -10)
    ph = phone("empty_phone", 0.95, 1.9, 0.18, body="clay", screen="sand", radius=0.17, rotation=rot,
               location=(0, 0, 0.95))
    # dotted outline ring around the screen (in the phone's local frame)
    sw, sh = 0.95 - 0.14 - 0.1, 1.9 - 0.14 - 0.1
    n_w, n_h = 5, 9
    pts = []
    for i in range(n_w):
        x = -sw / 2 + sw * i / (n_w - 1)
        pts += [(x, sh / 2), (x, -sh / 2)]
    for j in range(1, n_h - 1):
        y = -sh / 2 + sh * j / (n_h - 1)
        pts += [(sw / 2, y), (-sw / 2, y)]
    for k, (x, y) in enumerate(pts):
        d = sphere(f"dot{k}", 0.034, "clay", location=(x, y, 0.13), segments=16)
        d.parent = ph
    lf = leaf("empty_leaf", 0.5, 0.22, 0.07, token="gold", location=(0.02, -0.05, 0.16), rotation=(0, 0, 35), bend=15)
    lf.parent = ph


def build_icon_history():
    cylinder("clock_face", 0.85, 0.22, "clay", verts=64)
    slab("hand_min", 0.12, 0.6, 0.1, "primary", radius=0.05, location=(0, 0.26, 0.15))
    slab("hand_hour", 0.12, 0.42, 0.1, "primary", radius=0.05, location=(0.17, 0.08, 0.15), rotation=(0, 0, -60))
    sphere("clock_pin", 0.09, "gold", location=(0, 0, 0.17))


def build_icon_bookmark():
    w, h, r, notch = 1.0, 1.7, 0.16, 0.4
    pts = []
    # start at bottom-left, go up the left side, across the top, down the right, then the V notch
    left = [(-w / 2, -h / 2)]
    tl = [(-w / 2 + r * (1 - math.cos(radians(90 * i / 6))), h / 2 - r * (1 - math.sin(radians(90 * i / 6)))) for i in range(7)]
    tr = [(w / 2 - r * (1 - math.sin(radians(90 * i / 6))), h / 2 - r * (1 - math.cos(radians(90 * i / 6)))) for i in range(7)]
    right = [(w / 2, -h / 2)]
    pts = left + tl + tr + right + [(0, -h / 2 + notch)]
    obj = extrude_profile("bookmark", pts, 0.2, "gold", bevel_frac=0.35)
    obj.rotation_euler = (radians(80), 0, radians(-6))
    obj.location = (0, 0, 0.85)


def build_toast_check():
    box("check_short", (0.75, 0.3, 0.3), "sage", location=(-0.35, -0.2, 0), rotation=(0, 0, 45))
    box("check_long", (1.3, 0.3, 0.3), "sage", location=(0.22, 0.05, 0), rotation=(0, 0, -45))


def build_toast_error():
    box("cross_a", (1.4, 0.3, 0.3), "coral", rotation=(0, 0, 45))
    box("cross_b", (1.4, 0.3, 0.3), "coral", rotation=(0, 0, -45))


def build_empty_gallery():
    slab("gal_a", 1.1, 1.5, 0.08, "clayDeep", radius=0.14, location=(-0.6, 0.0, 0.0), rotation=(0, 0, 18))
    slab("gal_b", 1.1, 1.5, 0.08, "clay", radius=0.14, location=(0.0, 0.12, 0.16), rotation=(0, 0, 0))
    slab("gal_c", 1.1, 1.5, 0.08, "clayDeep", radius=0.14, location=(0.6, 0.0, 0.32), rotation=(0, 0, -18))


def build_logo():
    slab("logo_tile", 2.0, 2.0, 0.22, "primaryDeep", radius=0.5, bevel_frac=0.1)
    # Two leaflets joined at a stalk, like the existing brand mark
    leaf("logo_leaf_main", 1.25, 0.48, 0.2, token="gold", location=(0.02, 0.08, 0.2), rotation=(0, 0, 22), bend=18)
    leaf("logo_leaf_second", 0.95, 0.38, 0.17, token="gold", location=(-0.22, -0.22, 0.18), rotation=(0, 0, 8), bend=14)
    cylinder("logo_stalk", 0.05, 0.4, "gold", location=(0.72, 0.4, 0.16), rotation=(0, 90, 38), verts=16)


ASSETS = [
    # name, builder, display size (w, h), camera, extra kwargs
    ("hero_phone_stack", build_hero, (720, 560), "persp", {"fill": 0.86, "rx": 62, "rz": 12, "roll": -3.0, "light_distance": 6}),
    ("icon_frame", build_icon_frame, (28, 28), "iso", {}),
    ("icon_text", build_icon_text, (28, 28), "iso", {"fill": 0.86, "rx": 70, "rz": 25}),
    ("icon_image", build_icon_image, (28, 28), "iso", {"fill": 0.84}),
    ("icon_upload", build_icon_upload, (28, 28), "iso", {}),
    ("icon_layout", build_icon_layout, (28, 28), "iso", {}),
    ("icon_backdrop", build_icon_backdrop, (28, 28), "iso", {}),
    ("icon_rows_both", build_icon_rows_both, (28, 28), "iso", {}),
    ("icon_rows_one", build_icon_rows_one, (28, 28), "iso", {}),
    ("icon_reset", build_icon_reset, (28, 28), "iso", {"rx": 40}),
    ("tpl_phone_mini", build_tpl_phone, (44, 90), "iso", {"rx": 12, "rz": 8, "fill": 0.88}),
    ("export_both", build_export_both, (56, 56), "iso", {"fill": 0.82}),
    ("export_apple", build_export_apple, (56, 56), "iso", {}),
    ("export_play", build_export_play, (56, 56), "iso", {}),
    ("empty_frame", build_empty_frame, (160, 160), "iso", {"rx": 60, "rz": 18, "fill": 0.84}),
    ("icon_history", build_icon_history, (40, 40), "iso", {"rx": 38}),
    ("icon_bookmark", build_icon_bookmark, (40, 40), "iso", {}),
    ("toast_check", build_toast_check, (28, 28), "iso", {"rx": 30, "rz": 0}),
    ("toast_error", build_toast_error, (28, 28), "iso", {"rx": 30, "rz": 0}),
    ("empty_gallery", build_empty_gallery, (240, 240), "iso", {"rx": 42, "rz": 0, "fill": 0.84}),
    ("mockuply_logo_3d", build_logo, (512, 512), "iso", {"rx": 0, "rz": 0, "fill": 0.96}),
]

# --------------------------------------------------------------------------------------
# Grain tile (pure numpy, seamless)
# --------------------------------------------------------------------------------------


def _periodic_value_noise(size, cells, rng):
    """Smooth value noise on a torus so the tile wraps seamlessly."""
    grid = rng.random((cells, cells))
    x = np.linspace(0, cells, size, endpoint=False)
    xi = np.floor(x).astype(int)
    xf = x - xi
    s = xf * xf * (3 - 2 * xf)  # smoothstep
    xi0 = xi % cells
    xi1 = (xi + 1) % cells
    g00 = grid[np.ix_(xi0, xi0)]
    g10 = grid[np.ix_(xi1, xi0)]
    g01 = grid[np.ix_(xi0, xi1)]
    g11 = grid[np.ix_(xi1, xi1)]
    sy = s[:, None]
    sx = s[None, :]
    top = g00 * (1 - sx) + g01 * sx
    bot = g10 * (1 - sx) + g11 * sx
    return top * (1 - sy) + bot * sy


def write_grain_tile(size=256):
    if OPTS["only"] and "grain_tile" not in OPTS["only"]:
        return
    rng = np.random.default_rng(1309)
    noise = np.zeros((size, size))
    amp_total = 0.0
    for cells, amp in ((16, 0.35), (32, 0.45), (64, 0.6), (128, 0.8)):
        noise += _periodic_value_noise(size, cells, rng) * amp
        amp_total += amp
    noise /= amp_total
    fine = rng.random((size, size))  # per-pixel grain, trivially periodic
    v = 0.55 * (noise - 0.5) + 0.45 * (fine - 0.5)
    v = v / (v.std() + 1e-9) * 0.1 + 0.5  # grey 0.5 +- 0.1 (one sigma)
    v = np.clip(v, 0.0, 1.0)
    img = bpy.data.images.new("grain_tile", size, size, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    px = np.empty((size, size, 4), dtype=np.float32)
    px[..., 0] = v
    px[..., 1] = v
    px[..., 2] = v
    px[..., 3] = 1.0
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = os.path.join(OUT_DIR, "grain_tile.png")
    img.file_format = "PNG"
    img.save()
    print(f"[clay] wrote {img.filepath_raw}")


# --------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    reset_scene()
    setup_lights_and_cameras()
    calibrate_tokens()
    for name, builder, size, camera, kw in ASSETS:
        render_asset(name, builder, size, camera=camera, **kw)
    write_grain_tile()

    # Lay everything out for the saved .blend: unhide every asset collection
    for coll, _ in ASSET_COLLECTIONS:
        coll.hide_render = False
    if OPTS["blend"] and not OPTS["only"] and not OPTS["out"]:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH, compress=True)
        print(f"[clay] saved {BLEND_PATH}")
    print("[clay] done")


if __name__ == "__main__":
    main()
