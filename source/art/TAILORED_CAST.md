# Tailored cast geometry

**Scope:** Additive original Blender 4.3.2 production pass on the two-storey game's editable anatomical character master.

After replace_faces.py, tailor_cast.py adds parented clothing geometry to the existing hero and neighbor. Features: contoured hoodie waistband, physical folds around chest/pocket/sleeves, denim creases and cuff, robe shawl lapels, relaxed drape, waist shaping, sleeve cuffs, short trouser cuffs and discrete buttons.

Added geometry follows the pre-existing Arm_L/Arm_R and Legs_L/Legs_R hinge pivots, rather than floating as static scene objects. Every mesh uses a game's existing cloth material, so the final character_microdetail.py stage provides compatible tangent normal maps. Master is saved before environment UV2 AO baking.

The script preserves:
- two anatomical head mesh morph key sets (Smile/Frown/Blink);
- animation Action inventory, Godot's 9 clips and node hierarchy;
- gameplay layouts, four classic levels, eight new trials, collision/navigation and UI;
- mobile Compatibility renderer, static AO UV and material atlas.

It deliberately does NOT claim cloth simulation, physically accurate skinning, finger rigging, or match to the cinematic reference. See engine render evidence from the CI output before approving the look.
