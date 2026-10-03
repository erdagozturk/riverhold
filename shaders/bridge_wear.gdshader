shader_type spatial;
render_mode blend_mix, depth_draw_never;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void vertex(){VERTEX+=NORMAL*0.003;world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float dust=noise(world.xz*0.65)*noise(world.xz*2.3+5.0);
 float edge=smoothstep(0.9,1.45,abs(world.z));
 float tracks=1.0-smoothstep(0.07,0.26,abs(abs(world.z)-0.55));
 float grit=noise(world.xz*65.0);
 ALBEDO=mix(vec3(0.11,0.13,0.055),vec3(0.30,0.21,0.105),1.0-edge*0.65)*(0.83+grit*0.25);
 ROUGHNESS=0.97;
 ALPHA=clamp(smoothstep(0.16,0.56,dust)*0.34+edge*0.32+tracks*dust*0.45,0.0,0.82);
}
