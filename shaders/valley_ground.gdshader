shader_type spatial;
render_mode diffuse_burley;
// Keep the optional source slots compatible with the world's material loader.
uniform sampler2D rock_texture : source_color;
uniform sampler2D soil_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float broad=noise(p*0.08)*0.55+noise(mat2(vec2(0.8,-0.6),vec2(0.6,0.8))*p*0.21)*0.30+noise(p*0.71)*0.15;
 vec3 grass=mix(vec3(0.040,0.10,0.015),vec3(0.115,0.20,0.028),broad);
 float fine=noise(p*9.0)*0.6+noise(p*23.0)*0.4;
 vec3 source_grass=mix(texture(grass_texture,p*0.46).rgb,texture(grass_texture,mat2(vec2(0.8,-0.6),vec2(0.6,0.8))*p*0.19).rgb,0.45);
 vec3 source_soil=texture(soil_texture,p*0.55).rgb;
 float dirt=smoothstep(0.63,0.83,noise(p*0.28+8.0))*0.55;
 ALBEDO=mix(mix(grass,source_grass*0.62,0.60),source_soil*0.58,dirt)*(0.92+fine*0.16);
 ROUGHNESS=0.96;
}
