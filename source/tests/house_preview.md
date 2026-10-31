# Development status

This branch is a playable development build, not the requested final art quality.

Implemented: real menu launches, independent persistent Music/SFX volume, generated 60-second music cue, original four classic episodes, a six-room two-storey house, 18-step staircase traversal, eight short challenge variants using four existing trap mechanics, inventory, hiding, patrol/chase, reactions, progress and score saving, touch controls and tap-to-walk.

Blender pass: continuous head skin surfaces and reduced eye scale; nine baked transform clips per actor (idle/walk/sneak/run/pickup/plant_trap/react_slip/react_surprise/celebrate). The editable master is rebuilt by `art/refine_cast.py` from the exact saved Blendstra base. These are articulated part animations, not a finished skinned character rig or facial animation system.

Still required: character sculpting and clothing to the reference standard, detailed face/hand animation, full production animation set, the twelve-room house plus garden/garage from the concept, and implementation of the 24 narrative missions in assets/data/campaign_24_design.json. The eight challenges do not implement those 24 mission designs. Main-menu background is concept artwork; it is not a screenshot.

Do not merge or deploy based only on automated tests. Native close-ups show that the art is still below the supplied reference.

Local checks: eight challenges completed via movement, pickup, arming and actual AI trap collisions; staircase ascent/descent; independent two-finger input; menu/classic launch; save settings; nine animation clip presence and actual shoulder movement. OpenGL software renderer measured about 15 FPS with shadows and 28 FPS without shadows at 70% render scale; this is not physical phone performance.
