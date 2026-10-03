shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform bool wheat = false;
uniform sampler2D wind_texture : repeat_enable, filter_linear_mipmap;
uniform vec2 wind_velocity = vec2(0.55,0.22);
uniform float wind_strength : hint_range(0.0,1.0) = 0.34;
varying float height_blend;
varying vec3 world_pos;
void vertex() {
    height_blend=clamp(VERTEX.y,0.0,1.0);
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    vec2 wind_uv=world_pos.xz*0.027-wind_velocity*TIME*0.045;
    float field=texture(wind_texture,wind_uv).r*2.0-1.0;
    float gust=field*0.72+sin(world_pos.x*0.43+world_pos.z*0.28-TIME*1.5)*0.28;
    float bend=height_blend*height_blend*wind_strength;
    VERTEX.x += gust*bend*wind_velocity.x;
    VERTEX.z += gust*bend*wind_velocity.y;
    NORMAL=normalize(vec3(NORMAL.x*0.25,1.0,NORMAL.z*0.25));
}
void fragment() {
    float patch=sin(world_pos.x*0.24+world_pos.z*0.31)*0.5+0.5;
    vec3 root=mix(vec3(0.035,0.09,0.012),vec3(0.06,0.13,0.025),patch);
    vec3 tip=mix(vec3(0.14,0.30,0.045),vec3(0.30,0.39,0.075),patch);
    if(wheat){root=vec3(0.13,0.19,0.025);tip=vec3(0.58,0.36,0.065);}
    ALBEDO=mix(root,tip,height_blend);
    ROUGHNESS=0.9;
    BACKLIGHT=ALBEDO*0.12;
}
