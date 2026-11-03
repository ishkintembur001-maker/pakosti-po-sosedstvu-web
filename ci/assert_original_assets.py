#!/usr/bin/env python3
"""Prevent an original-asset game release with wrong 3D models or degraded scan."""
from hashlib import sha256
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1] / "source" / "assets" / "user_models"
actors = {
    "hero_rigged.glb": "b025917dd8e048afa45d66dca3679bde3f2398c6abc9a78fb411eeb900515840",
    "neighbor_rigged.glb": "3c6486c0cad10b5de895a579f04febc3eb4b2558a5b4182467778a31c00a55ca",
}
profiles = {
    "RESTORED_MOBILE_ORIGINAL_TEXTURE": {
        "house_lower_quality.glb": "e73d2a49e9039bf9a82d93d63cb5fcbed67e76a08a629f4544f27f8953cd0c30",
        "house_upper_quality.glb": "93de437ddf9fcfc4a7af7619866b300407403b27985cfd24e21bfad8f6ce1e17",
        "house_roof_quality.glb": "6abe008e246240538ad0bb0b03a196b2a109bec394ec132f8e8565f2a014756a",
    },
    "ORIGINAL_FULL_GEOMETRY": {
        "house_lower_master.glb": "c510ff66cea2d25feefbc70e4d570c33ceb7ec35178a4974aabe1da63fd5a80e",
        "house_upper_master.glb": "eab3cb0b5ec6a2ab79fc6410d0aa1318732770893e86ba10b578ef1148793f74",
        "house_roof_master.glb": "8cdc084cb50c63a3d99748c95f1e27af5577475d9fc02069e38ca98d4c84257e",
    },
}

def digest(path: Path) -> str:
    h = sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

invalid = []
for name, expected in actors.items():
    path = root / name
    if not path.is_file() or digest(path) != expected:
        invalid.append("Missing or changed original character: " + name)

valid_profiles = []
for profile, required in profiles.items():
    if all((root / name).is_file() for name in required):
        if all(digest(root / name) == expected for name, expected in required.items()):
            valid_profiles.append(profile)
        else:
            invalid.append("Incorrect or recompressed source model for " + profile)

if not valid_profiles:
    invalid.append("No complete verified high-detail owner-house profile installed")

if invalid:
    print("ORIGINAL_OWNER_ASSETS_REQUIRED", file=sys.stderr)
    for problem in invalid:
        print(" - " + problem, file=sys.stderr)
    sys.exit(1)

print("ORIGINAL_OWNER_ASSETS_OK:", ", ".join(valid_profiles))
