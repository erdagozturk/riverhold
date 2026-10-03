shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D material_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec2 atlas_origin = vec2(0.0, 0.0);
uniform float texture_scale = 0.18;
uniform vec4 tint : source_color = vec4(1.0);
uniform float roughness_value = 0.86;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 atlas_sample(vec2 uv) {
	vec2 atlas_uv = atlas_origin + fract(uv) * 0.5;
	return texture(material_atlas, atlas_uv).rgb;
}

void fragment() {
	vec3 weights = pow(abs(NORMAL), vec3(5.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	vec3 wx = atlas_sample(world_position.zy * texture_scale);
	vec3 wy = atlas_sample(world_position.xz * texture_scale);
	vec3 wz = atlas_sample(world_position.xy * texture_scale);
	ALBEDO = (wx * weights.x + wy * weights.y + wz * weights.z) * tint.rgb;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.25;
}
