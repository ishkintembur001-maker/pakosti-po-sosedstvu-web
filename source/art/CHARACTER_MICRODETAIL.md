# Character microdetail — development art pass

This is an **additive**, reproducible polish step. It does not change the four
classic episodes, eight house challenges, player movement, traps, skeletal
actions, facial blendshapes or static AO bakes.

The pipeline already builds both editable environment masters through
\`polish_environments.py\`. Then \`character_microdetail.py\` reopens them,
generates *original* 384×384 seamless micro-normal maps in Blender, and applies
tangent-space relief to existing character PBR materials. The pass keeps all
existing albedo and UV2 AO connections. It re-exports GLB with the original
gltf base-color corrections, preserving NLA animations and facial morphs.

New surfaces include cotton knit, twill denim, flannel robe, cap canvas, hair,
and subtle complexion detail. Small amplitude prevents exaggerated glossy
plastic or harsh fabric corrugation in the Compatibility renderer.

\`character_pbr_check.py\` parses **real exported GLB files** and fails CI if
microdetail textures or playable animation tracks are missing. Native Godot
tests and actual engine capture still run afterwards.

**Limitations:** This is a material pass, not the requested professional
sculpt/fully rigged production cast. Physical iPhone performance, cloth folds,
hair sculpt, full hand animation and cinematic lighting remain unverified.
PR #1 remains a draft, and Pages publishing is unchanged.
