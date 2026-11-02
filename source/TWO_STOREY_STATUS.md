# Mobile game development build

## Playable

A six-room two-storey house with an 18-step staircase, 24 playable mission-specific setups across six chapters, with 4–8 named traps, eight game-effect families and score bonuses, inventory, hiding, patrol/chase, saved progress and scores. The original four classic episodes remain available. The long-form storyboard from assets/data/campaign_24_design.json remains a design. The playable campaign now has 24 different mission titles, goals, named task sets, difficulty tiers and optional score bonuses on the existing six rooms. All 24 are playable variants of the established collection/arm/wait/escape mechanics. Requested individual prop animations, moving toys, visitors, puzzle minigames and true multi-floor neighbor patrol are not yet implemented; do not advertise them as finished. The neighbor's anger, range and chase speed escalate as traps fire. A catch starts a short slapstick scene and loses one life.

## Mobile interface

Responsive landscape menu/HUD, large touch targets and left stick, tap-to-collect, pause that freezes AI and timers, focus-loss pause, portrait rotation gate, saved Music/SFX controls and a graphics setting. Web uses 75% render resolution without dynamic shadows by default. Browser fullscreen is best effort; physical iPhone/Safari performance remains unverified.

## Characters

Faces now use derived Blender Studio CC0 quad topology instead of assembled face primitives. The committed source collection and license are in art/source/. replace_faces.py fits the cap, forelocks, eyebrows, moustache and actual textured eyeballs. It adds Smile, Frown and Blink morphs, restores the teal long-sleeve hoodie and makes the hero shorter than the neighbor. Godot drives facial weights separately from the nine existing articulated body clips. The same new characters and shared expression controller are also used in all four classic episodes.

These are basic part animations, not a finished full-body skeletal/finger rig or the 80-clip production design.

## Environment materials and grounding

The static house and classic apartment have separate baked ambient-occlusion atlases (1024 and 512 pixels), with a second UV channel. The shared cutaway shader preserves albedo, normal, roughness and AO maps. Smooth mode keeps baked shading and disables detail normal maps. Classic imports explicitly enable UV2 occlusion. The former raised floor-joint strips were removed because they aliased into black dots at the mobile render scale.

Wood now uses offline, 1024-pixel derivatives of Rob Tuytel / Poly Haven's CC0 Fine Grained Wood scan. Source URLs and hashes are recorded in art/source/materials/materials.json. Other fabric and wallpaper detail remains procedural. Actual raycast floor-height data grounds actors on rugs; subtle contact shadows follow them and disappear while hidden or climbing.

## Rebuild

Use Blender 4.3.2 and Godot 4.4.1. Run python3 source/art/make_textures.py, then Blender --background --python-exit-code 1 --python for source/art/build_assets.py, source/art/refine_cast.py and source/art/replace_faces.py and source/art/polish_environments.py in that order. Import source/project.godot in Godot. The checked gzip house is verified and unpacked by refine_cast.py. The small CC0 head collection makes face rebuilds independent of the full external 49 MB asset bundle.

## Validation and remaining work

Native Godot checks cover house completion, stair traversal, independent touch fingers, responsive layout/pause, body clips and facial morph weights. Environment tests also check AO and normal-map bindings, atlas size, UV2, rug grounding and contact-shadow visibility. Native close-up screenshots include neutral, smile, frown and blink poses. CI rebuilds both Blender masters, runs the tests, captures real engine frames and exports a Web preview as downloadable artifacts.

The supplied cinematic reference is still NOT met: clothing folds and cloth textures, hands, full acting animations, environment light/detail and the larger twelve-room concept house remain unfinished. The cinematic menu background is concept art, not an engine render. Pages publication remains blocked by visual review; passing automated tests alone is not visual acceptance.

## Audit notes (24-mission verification)

The camera and cutaway shader now show both existing floors simultaneously. Item labels appear only near the hero to avoid overcrowding. Temporary prank effects are cleared on restart. The bonus shown to players derives from implemented, testable conditions (no capture, par time or combo); original storyboard bonuses that need unavailable props or AI are not advertised as working.

## Patrol route fixes

The neighbor now uses mission-specific routes built from the actual trap sites. Four patterns alternate between left-to-right, right-to-left and two zigzags, all containing every active trap. Native tests cover route completeness for all 24 missions. This does not yet implement unique household schedules or full AI investigation for every authored storyline.

## Patrol regression repair

QA detected that route-only zigzags could strand a triggered prank in missions 14 and 22. Each mission now starts with a guaranteed full hallway sweep from x=-4.1 to x=3.7 before executing its individual patrol order. Tests enforce this safety sweep and still validate mission-specific waypoints. This correction must pass Godot CI before declaring the new behavior verified.
