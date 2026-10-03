shader_type sky;
uniform sampler2D day_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D morning_map : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D night_map : source_color, filter_linear_mipmap, repeat_enable;
uniform float daylight = 1.0;
uniform float twilight = 0.0;
void sky(){
 vec3 day=texture(day_map,SKY_COORDS).rgb;
 vec3 night=texture(night_map,SKY_COORDS).rgb;
 vec3 dawn=texture(morning_map,SKY_COORDS).rgb;
 COLOR=mix(mix(night,day,daylight),dawn,twilight*0.75);
}
