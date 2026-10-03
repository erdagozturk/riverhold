shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
uniform vec4 team_color: source_color=vec4(0.2,0.6,1.0,1.0);
void fragment(){
 float rim=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.5);
 ALBEDO=team_color.rgb;
 EMISSION=team_color.rgb*0.5;
 ALPHA=rim*0.32;
}
