shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void vertex(){ MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]); }
void fragment(){
 float height=1.0-UV.y;
 float n=noise(vec2(UV.x*5.0,height*5.0-TIME*3.5));
 float fine=noise(vec2(UV.x*13.0,height*11.0-TIME*6.0));
 float center=0.5+sin(height*7.0-TIME*5.0)*height*0.10;
 float width=(1.0-height)*0.34;
 float body=width-abs(UV.x-center)+(n-0.5)*0.15+(fine-0.5)*0.04;
 float alpha=smoothstep(-0.02,0.035,body)*smoothstep(0.0,0.09,height)*(1.0-smoothstep(0.88,1.0,height));
 vec3 color=mix(vec3(1.0,0.12,0.008),vec3(1.0,0.75,0.22),smoothstep(0.0,0.18,body));
 color=mix(color,vec3(1.0,0.93,0.65),smoothstep(0.15,0.27,body));
 ALBEDO=color; EMISSION=color*2.2; ALPHA=alpha;
}
