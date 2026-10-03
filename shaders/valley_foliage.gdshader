shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D leaf_texture:source_color,filter_linear_mipmap,repeat_enable;
uniform bool summer_canopy=false;
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float gust=sin(world.x*0.43+world.z*0.28-TIME*1.5)*0.55+sin(world.z*1.1-TIME*2.7)*0.2;
 VERTEX.x+=gust*0.038*max(VERTEX.y,0.0);
}
void fragment(){
 vec4 tex=texture(leaf_texture,UV);
 float luminance=dot(tex.rgb,vec3(0.2126,0.7152,0.0722));
 vec3 leaf=mix(vec3(0.015,0.055,0.006),vec3(0.16,0.31,0.035),clamp(luminance,0.0,1.0));
 if(summer_canopy){leaf*=vec3(1.05,0.98,0.94);}
 ALBEDO=leaf;
 ALPHA=tex.a;
 ALPHA_SCISSOR_THRESHOLD=0.38;
 ROUGHNESS=0.95;
 BACKLIGHT=ALBEDO*0.28;
}
