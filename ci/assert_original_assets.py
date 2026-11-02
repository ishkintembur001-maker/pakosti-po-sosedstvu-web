#!/usr/bin/env python3
"""Block native releases unless the owner's exact five 3D assets are present."""
from hashlib import sha256
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1] / "source" / "assets" / "user_models"
expected = {
    "hero_rigged.glb": "b025917dd8e048afa45d66dca3679bde3f2398c6abc9a78fb411eeb900515840",
    "neighbor_rigged.glb": "3c6486c0cad10b5de895a579f04febc3eb4b2558a5b4182467778a31c00a55ca",
    "house_lower_quality.glb": "e156e8b9e194cd3ab42ab39b893a71ffc5cb1151c8f179fac2f4064daa27d03e",
    "house_upper_quality.glb": "bb042cdda43a2ebcf57a6f3cf94476a419e3c6568778ae1c36dcba01ef9ecf34",
    "house_roof_quality.glb": "fb982126780c3ca405848996893a85d5f0ecbec9478276e414432f1e3dc8d4ae",
}

missing, changed = [], []
for name, digest in expected.items():
    path = root / name
    if not path.is_file():
        missing.append(name)
        continue
    h = sha256()
    with path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            h.update(block)
    if h.hexdigest() != digest:
        changed.append(name)

if missing or changed:
    print("ORIGINAL_OWNER_ASSETS_REQUIRED", file=sys.stderr)
    for name in missing:
        print("Missing: " + name, file=sys.stderr)
    for name in changed:
        print("Wrong or changed owner model: " + name, file=sys.stderr)
    print(
        "Native release blocked: do not substitute generated characters or rooms. "
        "Install the exact five assets from the owner's verified full project ZIP.",
        file=sys.stderr,
    )
    sys.exit(1)

print("ORIGINAL_OWNER_ASSETS_OK: original hero, neighbor, two floors and roof")
