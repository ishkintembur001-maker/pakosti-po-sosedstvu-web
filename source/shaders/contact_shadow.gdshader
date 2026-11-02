shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float opacity = 0.30;
void fragment() {
 float radius = length((UV - vec2(0.5)) * 2.0);
 float falloff = 1.0 - smoothstep(0.12, 1.0, radius);
 ALBEDO = vec3(0.055, 0.035, 0.025);
 ALPHA = falloff * falloff * opacity;
}
