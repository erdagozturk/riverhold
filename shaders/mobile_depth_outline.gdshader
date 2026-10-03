shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 outline_color : source_color = vec4(0.025,0.045,0.075,0.38);
uniform float thickness : hint_range(0.5,3.0) = 1.15;
uniform float threshold : hint_range(0.0001,0.05) = 0.006;

void vertex(){POSITION=vec4(VERTEX.xy,1.0,1.0);}
void fragment(){
	vec2 pixel=1.0/vec2(textureSize(depth_texture,0))*thickness;
	float c=texture(depth_texture,SCREEN_UV).r;
	float l=texture(depth_texture,SCREEN_UV-vec2(pixel.x,0.0)).r;
	float r=texture(depth_texture,SCREEN_UV+vec2(pixel.x,0.0)).r;
	float u=texture(depth_texture,SCREEN_UV-vec2(0.0,pixel.y)).r;
	float d=texture(depth_texture,SCREEN_UV+vec2(0.0,pixel.y)).r;
	float edge=max(max(abs(c-l),abs(c-r)),max(abs(c-u),abs(c-d)));
	float mask=smoothstep(threshold,threshold*2.5,edge);
	ALBEDO=outline_color.rgb;
	ALPHA=outline_color.a*mask;
}
