shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;
uniform sampler2D flow_noise : repeat_enable, filter_linear_mipmap;
uniform sampler2D wave_normal : hint_normal, repeat_enable, filter_linear_mipmap;

void vertex() {
    VERTEX.z += sin(UV.x * 13.0 + TIME * 1.7) * 0.035;
}

void fragment() {
    vec2 flow = vec2(UV.x * 1.25, UV.y * 0.38 - TIME * 0.24);
    float broad = texture(flow_noise, flow).r;
    float detail = texture(flow_noise, flow * vec2(3.4, 2.1) + vec2(0.3, -TIME * 0.12)).r;
    float turbulence = smoothstep(0.27, 0.74, broad * 0.6 + detail * 0.4);
    float edge = smoothstep(0.0, 0.10, UV.x) * smoothstep(0.0, 0.10, 1.0 - UV.x);
    edge *= smoothstep(0.0, 0.07, UV.y) * smoothstep(0.0, 0.10, 1.0 - UV.y);
    vec3 water = mix(vec3(0.06, 0.32, 0.40), vec3(0.70, 0.85, 0.83), turbulence);
    ALBEDO = water;
    EMISSION = water * 0.10;
    NORMAL_MAP = texture(wave_normal, flow * vec2(2.0, 0.4)).rgb;
    NORMAL_MAP_DEPTH = 0.22;
    ROUGHNESS = 0.24 + turbulence * 0.25;
    SPECULAR = 0.65;
    ALPHA = edge * (0.60 + turbulence * 0.38);
}
