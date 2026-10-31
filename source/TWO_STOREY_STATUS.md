# Development status

This branch is a playable development build, not the requested final art quality.

Implemented: real menu launches, independent persistent Music/SFX volume, generated 60-second music cue, original four classic episodes, a six-room two-storey house, 18-step staircase traversal, eight short challenge variants using four existing trap mechanics, inventory, hiding, patrol/chase, reactions, progress and score saving, touch controls and tap-to-walk.

Blender pass: continuous head skin surfaces and reduced eye scale; nine baked transform clips per actor (idle/walk/sneak/run/pickup/plant_trap/react_slip/react_surprise/celebrate). The editable master is rebuilt by `art/refine_cast.py` from the exact saved Blendstra base. These are articulated part animations, not a finished skinned character rig or facial animation system.

Still required: character sculpting and clothing to the reference standard, detailed face/hand animation, full production animation set, the twelve-room house plus garden/garage from the concept, and implementation of the 24 narrative missions in assets/data/campaign_24_design.json. The eight challenges do not implement those 24 mission designs. Main-menu background is concept artwork; it is not a screenshot.

Do not merge or deploy based only on automated tests. Native close-ups show that the art is still below the supplied reference.

Local checks: eight challenges completed via movement, pickup, arming and actual AI trap collisions; staircase ascent/descent; independent two-finger input; menu/classic launch; save settings; nine animation clip presence and actual shoulder movement. OpenGL software renderer measured about 15 FPS with shadows and 28 FPS without shadows at 70% render scale; this is not physical phone performance.

Rebuild from a fresh checkout: run `python3 source/art/make_textures.py`, run Blender with `--background --python source/art/build_assets.py`, then `--background --python source/art/refine_cast.py`; finally import `source/project.godot` in Godot 4.4.1. The base house is stored as a checked gzip asset; the refinement script verifies and unpacks it. CI uploads the actual Blender master, engine screenshots and Web preview as artifacts without publishing Pages.

## Mobile pass

Landscape viewport expands to the device aspect instead of letterboxing. HUD uses edge padding, a larger left stick and a 94-unit contextual action button. Pause freezes AI, timers and movement; leaving focus pauses the house. A portrait gate pauses gameplay and asks the player to rotate. Tapping a pickup routes the hero and collects it. Main menu, mission grid and settings use touch-sized controls. Web defaults to 75% render scale without dynamic shadows, with a saved graphics toggle. Browser fullscreen is best effort and is not guaranteed on iPhone Safari.

Validated in native Godot: three landscape layouts, actual pause freeze, tap-to-collect, portrait freeze/resume, independent multitouch, all eight house challenges and four classic episodes. Web export tested at 844x390 and 390x844 in touch-enabled Chromium with no reported JS/GDScript errors. This is not a physical iPhone/Safari benchmark.

Visual quality remains BLOCKED. Existing character geometry is a prototype and does not meet the provided reference; no replacement character assets were integrated in this mobile pass. Mobile UI changes do not resolve that gap. No Pages publication is authorized by the automated test results alone.
