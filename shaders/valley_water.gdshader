shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D wave_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D wave_normal_b : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_noise : repeat_enable, filter_linear_mipmap;
uniform sampler2D scene_color : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest;
uniform int obstacle_count = 0;
uniform vec4 obstacles[24];

uniform vec3 shallow_color : source_color = vec3(0.075, 0.56, 0.62);
uniform vec3 deep_color : source_color = vec3(0.012, 0.13, 0.23);
uniform vec3 foam_color : source_color = vec3(0.82, 0.94, 0.90);
uniform vec3 caustics_color : source_color = vec3(0.48, 0.83, 0.66);
uniform float caustics_strength : hint_range(0.0, 1.0) = 0.18;
uniform vec3 shoreline_dark : source_color = vec3(0.018, 0.095, 0.105);
uniform float shoreline_darkness : hint_range(0.0, 1.0) = 0.58;
varying vec3 world_position;

float linear_depth(vec2 uv, mat4 inverse_projection) {
	float d = texture(scene_depth, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(uv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
#endif
	vec4 view_position = inverse_projection * vec4(ndc, 1.0);
	return -view_position.z / view_position.w;
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_position.z * 1.3 - TIME * 1.1) * 0.04
		+ sin(world_position.x * 2.1 + world_position.z * 0.7 - TIME * 0.8) * 0.025;
}

void fragment() {
	vec2 p = world_position.xz;
	vec2 flow = normalize(vec2(-cos((-p.y - 8.0) * 0.072) * 0.40 * smoothstep(8.0, 36.0, -p.y), 1.0));
	float wake = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= obstacle_count) { break; }
		vec2 delta = p - obstacles[i].xy;
		float radius = obstacles[i].z;
		float influence = exp(-dot(delta, delta) / (radius * radius * 10.0));
		flow += vec2(delta.x, -delta.y * 0.18) * influence * 0.5;
		float downstream = smoothstep(0.0, 0.8, delta.y) * (1.0 - smoothstep(1.0, 5.5, delta.y));
		float trail = exp(-pow(delta.x / (radius + max(delta.y, 0.0) * 0.19), 2.0) * 2.0);
		wake = max(wake, downstream * trail);
	}
	flow = normalize(flow);

	float speed = 0.75 + texture(foam_noise, p * 0.025).r * 0.65;
	vec2 stream_a = p * vec2(0.18, 0.085) - flow * TIME * 0.055 * speed;
	vec2 stream_b = p.yx * vec2(0.21, 0.16) + vec2(-TIME * 0.024, TIME * 0.018);
	vec3 n1 = texture(wave_normal, stream_a).xyz * 2.0 - 1.0;
	vec3 n2 = texture(wave_normal_b, stream_b).xyz * 2.0 - 1.0;
	vec2 slope = (n1.xy + n2.xy * 0.52) * 0.50;
	vec3 water_normal = normalize(vec3(slope.x, 1.0, slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(water_normal, 0.0)).xyz);

	float water_depth = -VERTEX.z;
	float thickness = max(0.0, linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX) - water_depth);
	float depth_mix = smoothstep(0.12, 5.8, thickness);
	vec2 refract_uv = clamp(SCREEN_UV + slope * min(thickness, 2.0) * 0.0055, vec2(0.001), vec2(0.999));
	if (linear_depth(refract_uv, INV_PROJECTION_MATRIX) < water_depth) { refract_uv = SCREEN_UV; }
	vec3 beneath = texture(scene_color, refract_uv).rgb;
	vec3 absorption = exp(-vec3(0.82, 0.27, 0.16) * thickness);
	vec3 depth_tint = mix(shallow_color, deep_color, depth_mix);
	vec3 body = beneath * absorption + depth_tint * (vec3(1.0) - absorption);

	float noise = texture(foam_noise, stream_a * 2.3).r;
	float shore = 1.0 - smoothstep(0.025, 0.34, thickness);
	float contact_band = smoothstep(0.015, 0.08, thickness) * (1.0 - smoothstep(0.34, 1.10, thickness));
	float cells = texture(foam_noise, p * vec2(1.25, 0.72) - flow * TIME * 0.21).r;
	float broken = smoothstep(0.48, 0.60, cells);
	float foam = max(shore * broken, wake * broken * smoothstep(0.44, 0.68, noise) * 0.55);
	float streak = texture(foam_noise, p * vec2(0.70, 0.11) - flow * TIME * 0.13).r;
	float breakup = texture(foam_noise, p * 0.92 - flow * TIME * 0.19).r;
	float current_foam = smoothstep(0.53, 0.70, streak) * smoothstep(0.43, 0.66, breakup);
	float current_lines = current_foam * (0.08 + 0.18 * smoothstep(0.18, 0.72, noise));
	foam = max(foam, max(current_foam * wake * 0.34, current_lines));

	// Two scrolling cells create restrained projected caustics only in visible shallow water.
	float caustic_a = texture(foam_noise, p * 0.58 + vec2(TIME * 0.035, -TIME * 0.028)).r;
	float caustic_b = texture(foam_noise, p.yx * 0.71 + vec2(-TIME * 0.026, TIME * 0.031)).r;
	float caustics = pow(clamp(caustic_a * caustic_b * 1.55, 0.0, 1.0), 3.0)
		* (1.0 - depth_mix) * smoothstep(0.30, 1.5, thickness) * (1.0 - foam);

	float facing = clamp(dot(water_normal, normalize(-VERTEX)), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 4.0);
	float glint = pow(max(0.0, sin(p.y * 1.9 + p.x * 0.45 - TIME * 1.2)) * max(0.0, n1.x), 6.0) * 0.20;

	ALBEDO = mix(body * 0.56, foam_color, foam);
	ALBEDO += caustics_color * caustics * caustics_strength;
	ALBEDO = mix(ALBEDO, shoreline_dark, contact_band * shoreline_darkness * (1.0 - foam));
	ALBEDO = mix(ALBEDO, vec3(0.34, 0.66, 0.76), fresnel * 0.24);
	EMISSION = body * 0.20 * (1.0 - foam) + caustics_color * caustics * 0.08 + vec3(0.86, 0.72, 0.42) * glint;
	METALLIC = 0.0;
	SPECULAR = 0.82;
	ROUGHNESS = mix(mix(0.27, 0.16, contact_band), 0.76, foam);
	ALPHA = 1.0;
}

