shader_type canvas_item;
uniform float night_strength : hint_range(0.0,1.0) = 0.0;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float lum=dot(c.rgb,vec3(0.2126,0.7152,0.0722));
 // Cool shadows retain the original forms; bright water catches soft moonlight.
 vec3 moonlit=c.rgb*vec3(0.51,0.65,0.87);
 moonlit+=vec3(0.12,0.19,0.27)*pow(max(lum,0.0),2.4);
 COLOR=vec4(mix(c.rgb,clamp(moonlit,0.0,1.0),night_strength),c.a);
}
