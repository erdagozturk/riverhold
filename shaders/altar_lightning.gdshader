shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

uniform vec3 main_color : source_color = vec3(0.82,0.95,1.0);
uniform vec3 effect_color : source_color = vec3(0.12,0.48,1.0);
uniform float speed = 7.0;
uniform float emission_power = 3.2;
uniform float seed = 0.0;

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p){
	float v=0.0;float a=0.5;
	for(int i=0;i<6;i++){v+=noise(p)*a;p=p*2.03+vec2(17.2,9.1);a*=0.5;}
	return v;
}
void fragment(){
	vec2 uv=UV;
	float taper=smoothstep(0.0,0.08,uv.y)*smoothstep(1.0,0.90,uv.y);
	float displacement=(fbm(vec2(uv.y*8.0,TIME*speed+seed))-0.5)*0.48*taper;
	float core=abs((uv.x-0.5)-displacement);
	float bolt=smoothstep(0.12,0.005,core);
	float halo=smoothstep(0.34,0.02,core)*0.32;
	float flicker=0.72+0.28*hash(vec2(floor(TIME*24.0),seed));
	vec3 color=mix(effect_color,main_color,bolt)*flicker;
	ALBEDO=color;
	EMISSION=color*emission_power;
	ALPHA=(bolt+halo)*taper;
}
