shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ao_tex : hint_default_white, filter_linear_mipmap, repeat_disable;
uniform bool textured = false;
uniform bool normal_mapped = false;
uniform bool rough_mapped = false;
uniform bool ao_mapped = false;
uniform bool detail_normals = true;
uniform int rough_channel = 1;
uniform float normal_scale = 0.35;
uniform float ao_strength = 0.45;
uniform float cutoff = 99.0;
uniform float rough = 0.8;
uniform float metal = 0.0;
varying float world_y;
void vertex() {
 world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
void fragment() {
 if (world_y > cutoff) { discard; }
 ALBEDO = tint.rgb * (textured ? texture(tex, UV).rgb : vec3(1.0));
 if (ao_mapped) {
  float contact = texture(ao_tex, UV2).r;
  ALBEDO *= mix(1.0, contact, ao_strength);
 }
 vec4 rough_sample = rough_mapped ? texture(rough_tex, UV) : vec4(1.0);
 float rough_value = rough_channel == 4 ? dot(rough_sample.rgb, vec3(0.333333)) : rough_sample[clamp(rough_channel, 0, 3)];
 ROUGHNESS = rough * rough_value;
 METALLIC = metal;
 if (normal_mapped && detail_normals) {
  NORMAL_MAP = texture(normal_tex, UV).rgb;
  NORMAL_MAP_DEPTH = normal_scale;
 }
}
