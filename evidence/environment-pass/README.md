# Native Godot environment pass

Real Godot 4.4.1 Compatibility-renderer captures, 1280 x 720, from source/tests/environment_capture.gd. living_ao and living_without_ao use the same frozen camera, actors, light and material state; only baked AO strength changes. Room closeups and the overview use the optional detailed preset (MSAA 2x and detail normals). gameplay_smooth uses the mobile preset (75% internal resolution, no detail normals). Screenshot WebP files are derived from native PNG captures.

Blender polish removes 108 subpixel raised decorative floor joints, bakes static UV2 AO (house 1024, classic apartment 512), and derives tinted wood from the checked CC0 scan. Automated tests passed for all four classic episodes, eight house challenges, stairs, touch/layout, basic body clips, expressions and material/floor bindings.

These frames do not match the supplied cinematic target yet. Clothing, hands, hair, facial acting, furniture detail and environment lighting still require substantial art work. The 24 narrative missions remain designs. No physical iPhone performance result is claimed, and this branch does not deploy Pages.
