shader_type spatial;
render_mode diffuse_burley;
uniform vec2 road_start=vec2(0.0);
uniform vec2 road_end=vec2(1.0);
uniform float road_half_width=1.0;
uniform sampler2D dirt_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone_map : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world;
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453),fract(sin(dot(i+vec2(1,0),vec2(127.1,311.7)))*43758.5453),f.x),mix(fract(sin(dot(i+vec2(0,1),vec2(127.1,311.7)))*43758.5453),fract(sin(dot(i+vec2(1,1),vec2(127.1,311.7)))*43758.5453),f.x),f.y);}
vec2 hash2(vec2 p){return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world.xz*2.1;
 vec2 cell=floor(p), f=fract(p), winner=vec2(0.0);
 float first=8.0,second=8.0;
 for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
  vec2 offset=vec2(float(x),float(y));
  vec2 seed=offset+0.5+(hash2(cell+offset)-0.5)*0.54-f;
  float d=dot(seed,seed);
  if(d<first){second=first;first=d;winner=cell+offset;}else{second=min(second,d);}
 }
 float stone=smoothstep(0.025,0.085,second-first);
 float tint=hash2(winner).x;
 vec3 face=mix(vec3(0.24,0.18,0.105),vec3(0.39,0.30,0.18),tint);
 float grain=hash2(floor(world.xz*95.0)).y;
 float weather=noise(world.xz*0.43);
 float moss=smoothstep(0.53,0.78,weather)*(1.0-stone)*0.7;
 vec3 joint=mix(vec3(0.16,0.13,0.08),vec3(0.12,0.18,0.045),moss);
 vec3 paving=mix(joint,face*(0.86+grain*0.12),stone);
 vec2 route=road_end-road_start;
 float t=clamp(dot(world.xz-road_start,route)/max(dot(route,route),0.001),0.0,1.0);
 float lateral=length(world.xz-(road_start+t*route));
 float edge=smoothstep(road_half_width*0.40,road_half_width*0.92,lateral);
 float dust=clamp(smoothstep(0.32,0.72,noise(world.xz*0.25+13.0))*0.72+edge*0.68,0.0,0.96);
 vec3 soil=mix(vec3(0.13,0.078,0.035),vec3(0.24,0.16,0.073),noise(world.xz*4.0));
 float wheel=1.0-smoothstep(0.10,0.24,abs(abs(world.x*0.42+world.y*0.18)-0.52));
 dust=clamp(dust+wheel*noise(world.xz*1.7+31.0)*0.17,0.0,0.96);
 ALBEDO=mix(mix(paving*0.72,texture(stone_map,world.xz*0.38).rgb*0.52,0.64),mix(soil,texture(dirt_map,world.xz*0.65).rgb*0.48,0.68),dust);
 ALPHA=1.0-smoothstep(road_half_width-0.35,road_half_width,lateral+noise(world.xz*9.0)*0.15);
 ROUGHNESS=0.92;
}
