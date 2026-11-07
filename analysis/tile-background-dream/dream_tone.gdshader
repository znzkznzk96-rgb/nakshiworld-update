shader_type canvas_item;
uniform float strength = 0.28;
void fragment(){
 vec4 c = texture(TEXTURE, UV);
 float lum = dot(c.rgb, vec3(0.2126,0.7152,0.0722));
 vec3 shadow = vec3(0.21,0.16,0.43);
 vec3 highlight = vec3(0.94,0.87,1.0);
 vec3 dreamy = mix(shadow,highlight,smoothstep(0.0,1.0,lum));
 vec3 result = mix(c.rgb,dreamy,strength);
 result += vec3(0.015,0.016,0.025);
 COLOR = vec4(clamp(result,0.0,1.0),c.a);
}
