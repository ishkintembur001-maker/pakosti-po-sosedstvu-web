# Art-direction skill: Premium characters and house

Project: Pakosti po sosedstvu 3D, Godot 4.4 mobile, Blender 4.3.2.

The user's actual reference shows a mischievous boy with a backwards red
baseball cap, expressive large brown eyes, freckles, asymmetrical brown hair,
teal hoodie, blue denim, and believable anatomy. The neighbor is heavy,
angry, thick-browed and mustached, with a plaid robe and a broad torso.
The interior is a richly furnished warm two-story home.

## Process for every visual change
1. Inspect source screenshots from a real Godot frame, close-up and at game scale.
2. Prioritize character silhouette and anatomical volume over cosmetic decals.
3. Alter editable mesh geometry in Blender, not only procedural shader colors.
4. Retain all three facial blend shapes, nine named game actions, body pivots,
   all four classic episodes, eight house challenges and mobile touch input.
5. Run Blender, native Godot import, gameplay tests, and actual engine captures.
6. Compare the same camera framing before/after.
7. Reject black floating seams, plastic skin, crudely faceted limbs,
   repeated hair tubes and empty interiors even if CI says success.
8. Track performance on real phone hardware; Mesa llvmpipe FPS is not a phone result.
9. Do not publish or restore a web build; development is mobile native only.

## Acceptance criteria
- Silhouettes immediately distinguish hero and neighbor at 960x540.
- Face close-ups retain expressions and no black/clipped geometry.
- Polished hoodie, robe, pants, hands, eyebrows, moustache and hair.
- Dense but readable furniture, practical lighting and grounded contact shadows.
- Screenshots show substantive improvement, not merely extra objects.
- Real reference fidelity is not claimed without user's visual approval.

The scripted sculpture stage is source/art/sculpt_proportions.py.
This file is project documentation for connected assistants; it is not
a newly installed or registered ChatGPT plugin.
