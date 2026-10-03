shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec4 team_color:source_color=vec4(0.02,0.26,0.60,1);
void vertex(){float free_edge=UV.y;VERTEX.z+=sin(TIME*2.7+UV.y*5.0+UV.x*3.0)*0.045*free_edge;}
void fragment(){
 vec2 p=UV-vec2(0.5,0.43);
 float stem=step(abs(p.x),0.036)*step(abs(p.y),0.22);
 float head=1.0-smoothstep(0.06,0.072,length(p-vec2(0,-0.14)));
 float arms=step(abs(p.y+0.01),0.022)*step(abs(p.x),0.15);
 float feet=step(abs(p.y-0.17),0.025)*step(abs(p.x),0.105);
 float emblem=max(max(stem,head),max(arms,feet));
 float border=step(UV.x,0.025)+step(0.975,UV.x);
 ALBEDO=mix(team_color.rgb,vec3(0.86,0.82,0.66),clamp(emblem+border,0.0,1.0));
 ROUGHNESS=0.92;
}
