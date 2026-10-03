shader_type spatial;
render_mode blend_mix, depth_draw_never, shadows_disabled;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float patches=noise(world.xz*1.3+world.y*0.3);
 float earth=(1.0-smoothstep(0.45,1.55+patches*0.6,world.y));
 float stains=smoothstep(0.58,0.84,noise(world.xz*0.42+vec2(world.y*0.9,0.0)))*0.12;
 ALBEDO=mix(vec3(0.13,0.105,0.065),vec3(0.16,0.20,0.07),patches);
 ALPHA=clamp(earth*(0.15+patches*0.24)+stains,0.0,0.42);
 ROUGHNESS=1.0;
}
