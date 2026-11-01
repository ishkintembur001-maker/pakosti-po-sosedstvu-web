"""Mobile-friendly micro-surface detail for the EXISTING game characters.

Run after polish_environments.py. Reopens its editable Blender masters, adding
repeating tangent-space normal maps without replacing complexion, UV2 AO, PBR
albedo, facial blendshapes, skeleton/transform actions or existing level meshes.

Only authored derivative images are generated here; no third-party images.
"""
import bpy
import json
import os
import struct
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
N = 384
TAU = np.float32(2.0 * np.pi)

# Roughness and normal amplitude are deliberately restrained for a mobile display.
SURFACES = {
    "Petrol knit cotton": ("knit", 0.90, 0.36),
    "Indigo denim": ("denim", 0.91, 0.37),
    "Burgundy plaid robe": ("flannel", 0.94, 0.34),
    "Blue check shorts": ("flannel", 0.93, 0.30),
    "Carmine canvas": ("canvas", 0.87, 0.29),
    "Woven red cap": ("canvas", 0.87, 0.29),
    "Cap canvas panels": ("canvas", 0.91, 0.24),
    "Anatomical skin complexion": ("skin", 0.77, 0.09),
    "Groomed chestnut": ("hair", 0.78, 0.16),
}
# Same color correction as polish_environments.py; the re-export must not
# override its successfully verified wood and wallpaper palette.
PALETTE = {
    "Honey oak • grain": "9d7653",
    "Walnut • polished edges": "513c2c",
    "Sage damask • woven wallpaper": "728571",
    "Upstairs powder blue wallpaper": "829b9b",
    "Dusty rose bedroom wallpaper": "92766b",
    "Oxblood upholstery • woven checks": "87504a",
    "Muted jade glazed tile": "6b8980",
    "Persian wool • ornamental border": "833d3e",
}

def linear_channel(value):
    return value / 12.92 if value < 0.04045 else ((value + 0.055) / 1.055) ** 2.4

def linear_hex(value):
    return [linear_channel(int(value[i:i+2], 16) / 255) for i in (0, 2, 4)]

def image_for(style):
    name = "PAKOSTI_MicroNormal_" + style
    existing = bpy.data.images.get(name)
    if existing is not None:
        return existing
    y, x = np.mgrid[:N, :N].astype(np.float32)
    u, v = x / np.float32(N), y / np.float32(N)
    if style == "knit":
        relief = 0.62 * np.cos(TAU * 64 * u) + 0.47 * np.cos(TAU * 48 * v)
        relief += 0.24 * np.sin(TAU * (64 * u + 48 * v))
    elif style == "denim":
        relief = 0.57 * np.sin(TAU * (72 * u + 48 * v))
        relief += 0.28 * np.cos(TAU * 84 * u) + 0.16 * np.sin(TAU * 48 * v)
    elif style == "flannel":
        relief = 0.46 * np.cos(TAU * 48 * u) + 0.46 * np.cos(TAU * 48 * v)
        relief += 0.15 * np.sin(TAU * (48 * u + 48 * v))
    elif style == "canvas":
        relief = 0.54 * np.cos(TAU * 58 * u) + 0.44 * np.cos(TAU * 58 * v)
    elif style == "hair":
        relief = 0.37 * np.cos(TAU * 96 * u) + 0.16 * np.sin(TAU * (16 * u + 4 * v))
    else:
        relief = 0.18 * np.sin(TAU * 64 * u) * np.sin(TAU * 64 * v)
        relief += 0.07 * np.cos(TAU * 96 * u)
    # Roll-based periodic finite differences preserve edge tiling.
    du = (np.roll(relief, -1, 1) - np.roll(relief, 1, 1)) * 0.5
    dv = (np.roll(relief, -1, 0) - np.roll(relief, 1, 0)) * 0.5
    direction = np.stack((-du * 0.30, -dv * 0.30, np.ones_like(du)), axis=2)
    direction /= np.linalg.norm(direction, axis=2, keepdims=True)
    rgba = np.empty((N, N, 4), dtype=np.float32)
    rgba[:, :, :3] = direction * 0.5 + 0.5
    rgba[:, :, 3] = 1.0
    image = bpy.data.images.new(name, width=N, height=N, alpha=True)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(rgba.ravel())
    image.file_format = "PNG"
    image.pack()
    return image

def add_detail(material):
    if not material.use_nodes:
        return False
    base_name = material.name.split(" / ", 1)[-1]
    selected = next(((key, val) for key, val in SURFACES.items()
                     if base_name == key or base_name.startswith(key + ".")), None)
    if selected is None:
        return False
    key, (style, roughness, strength) = selected
    nodes = material.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    if shader is None:
        return False
    existing_node = nodes.get("PAKOSTI Tangent Microdetail")
    if existing_node is not None:
        return False
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = "PAKOSTI Authored MicroNormal"
    texture.image = image_for(style)
    texture.extension = "REPEAT"
    texture.interpolation = "Linear"
    texture.location = (-780, -440)
    normal = nodes.new("ShaderNodeNormalMap")
    normal.name = "PAKOSTI Tangent Microdetail"
    normal.inputs["Strength"].default_value = strength
    normal.location = (-480, -430)
    material.node_tree.links.new(texture.outputs["Color"], normal.inputs["Color"])
    # Character normals only: static UV2 AO is retained on environment materials.
    for link in list(shader.inputs["Normal"].links):
        material.node_tree.links.remove(link)
    material.node_tree.links.new(normal.outputs["Normal"], shader.inputs["Normal"])
    if not shader.inputs["Roughness"].is_linked:
        shader.inputs["Roughness"].default_value = roughness
    material["pakosti_microdetail"] = style
    return True

def export_to_glb(tag, path):
    for obj in bpy.data.objects:
        if obj.animation_data is None:
            continue
        for track in obj.animation_data.nla_tracks:
            track.mute = False
        if obj.animation_data.nla_tracks:
            obj.animation_data.action = obj.animation_data.nla_tracks[0].strips[0].action
    bpy.ops.export_scene.gltf(
        filepath=path, export_format="GLB",
        export_animations=True, export_animation_mode="NLA_TRACKS",
        export_nla_strips=True, export_force_sampling=True,
        export_frame_range=False, export_cameras=False,
        export_lights=False, export_morph=True,
    )
    binary = open(path, "rb").read()
    json_length = struct.unpack_from("<I", binary, 12)[0]
    doc = json.loads(binary[20:20 + json_length])
    tail = binary[20 + json_length:]
    for material in doc.get("materials", []):
        name = material.get("name", "")
        pbr = material.get("pbrMetallicRoughness", {})
        if name == "Anatomical skin complexion":
            pbr["baseColorFactor"] = linear_hex("d7ab92") + [1.0]
        source = name.split(" / ", 1)[-1]
        if name.startswith(tag + " / ") and source in PALETTE:
            pbr["baseColorFactor"] = linear_hex(PALETTE[source]) + [1.0]
            if pbr.get("metallicRoughnessTexture"):
                pbr["roughnessFactor"] = 1.0
    encoded = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    encoded += b" " * (-len(encoded) % 4)
    with open(path, "wb") as out:
        out.write(struct.pack("<III", 0x46546C67, 2, 20 + len(encoded) + len(tail)))
        out.write(struct.pack("<II", len(encoded), 0x4E4F534A))
        out.write(encoded)
        out.write(tail)
    n_maps = sum("normalTexture" in m for m in doc.get("materials", []))
    print("CHARACTER_NORMAL_EXPORT_OK", tag, n_maps, flush=True)

for tag, master, target in [
    ("House", "House_lit.blend", "two_storey.glb"),
    ("Apartment", "Apartment_lit.blend", "apartment_cast.glb"),
]:
    source_path = os.path.join(ROOT, "art", master)
    if not os.path.isfile(source_path):
        raise RuntimeError("Missing previous environment pass: " + source_path)
    bpy.ops.wm.open_mainfile(filepath=source_path)
    modified = [m.name for m in list(bpy.data.materials) if add_detail(m)]
    if len(modified) < 4:
        raise RuntimeError(tag + ": expected at least four cast/detail materials; got " + str(modified))
    bpy.ops.wm.save_as_mainfile(filepath=source_path)
    export_to_glb(tag, os.path.join(ROOT, "assets", "models", target))
    print("CHARACTER_MICRODETAIL_OK", tag, len(modified), flush=True)
