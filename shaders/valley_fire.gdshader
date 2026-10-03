shader_type spatial;
render_mode unshaded, cull_disabled;
void vertex(){VERTEX.x+=sin(TIME*9.0+VERTEX.y*9.0)*max(VERTEX.y,0.0)*0.13;}
void fragment(){
 vec3 fire=mix(vec3(1.0,0.11,0.006),vec3(1.0,0.66,0.10),UV.y);
 ALBEDO=fire;
 EMISSION=fire*2.2;
}
