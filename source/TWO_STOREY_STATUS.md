# Mobile game development build

## Playable

A six-room two-storey house with an 18-step staircase, eight short challenges using four existing trap types, inventory, hiding, patrol/chase, saved progress and scores. The original four classic episodes remain available. The 24 narrative missions in assets/data/campaign_24_design.json are still designs; the eight challenges do not implement them.

## Mobile interface

Responsive landscape menu/HUD, large touch targets and left stick, tap-to-collect, pause that freezes AI and timers, focus-loss pause, portrait rotation gate, saved Music/SFX controls and a graphics setting. Web uses 75% render resolution without dynamic shadows by default. Browser fullscreen is best effort; physical iPhone/Safari performance remains unverified.

## Characters

Faces now use derived Blender Studio CC0 quad topology instead of assembled face primitives. The committed source collection and license are in art/source/. replace_faces.py fits the cap, forelocks, eyebrows, moustache and actual textured eyeballs. It adds Smile, Frown and Blink morphs, restores the teal long-sleeve hoodie and makes the hero shorter than the neighbor. Godot drives facial weights separately from the nine existing articulated body clips.

These are basic part animations, not a finished full-body skeletal/finger rig or the 80-clip production design.

## Rebuild

Use Blender 4.3.2 and Godot 4.4.1. Run python3 source/art/make_textures.py, then Blender --background --python for source/art/build_assets.py, source/art/refine_cast.py and source/art/replace_faces.py in that order. Import source/project.godot in Godot. The checked gzip house is verified and unpacked by refine_cast.py. The small CC0 head collection makes face rebuilds independent of the full external 49 MB asset bundle.

## Validation and remaining work

Native Godot checks cover house completion, stair traversal, independent touch fingers, responsive layout/pause, body clips and facial morph weights. Native close-up screenshots include neutral, smile, frown and blink poses. CI rebuilds both Blender masters, runs the tests, captures real engine frames and exports a Web preview as downloadable artifacts.

The supplied cinematic reference is still NOT met: clothing folds and cloth textures, hands, full acting animations, environment light/detail and the larger twelve-room concept house remain unfinished. The cinematic menu background is concept art, not an engine render. Pages publication remains blocked by visual review; passing automated tests alone is not visual acceptance.
