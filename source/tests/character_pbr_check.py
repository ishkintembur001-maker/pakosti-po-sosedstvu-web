"""Validate GLB microdetail *after* the Blender pass.

This deliberately checks the real exported GLB instead of trusting Blender's
in-memory nodes. It never treats procedural material nodes as exported textures.
"""
import json
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pairs = [
    ("two_storey.glb", 4),
    ("apartment_cast.glb", 4),
]
total = 0
for filename, minimum in pairs:
    path = os.path.join(ROOT, "assets", "models", filename)
    with open(path, "rb") as stream:
        header = stream.read(20)
        if len(header) != 20:
            raise AssertionError(filename + ": truncated GLB header")
        magic, version, length, chunk_length, chunk_type = struct.unpack("<IIIII", header)
        if magic != 0x46546C67 or version != 2 or chunk_type != 0x4E4F534A:
            raise AssertionError(filename + ": not a GLB v2 file")
        if os.path.getsize(path) != length:
            raise AssertionError(filename + ": GLB declared length differs")
        doc = json.loads(stream.read(chunk_length))
    materials = doc.get("materials", [])
    textured = [m["name"] for m in materials
                if "normalTexture" in m
                and any(term.lower() in m["name"].lower() for term in
                        ["knit", "denim", "plaid", "canvas", "skin complexion",
                         "shorts", "chestnut"])]
    if len(textured) < minimum:
        raise AssertionError("%s: expected %d normal-mapped character materials, found %s" %
                             (filename, minimum, textured))
    animations = doc.get("animations", [])
    if not animations:
        raise AssertionError(filename + ": gameplay animation tracks missing")
    print("CHARACTER_GLTF_QA_OK", filename, "materials", len(textured),
          "animations", len(animations), flush=True)
    total += len(textured)
print("CHARACTER_PBR_QA_SUCCESS", total, flush=True)
