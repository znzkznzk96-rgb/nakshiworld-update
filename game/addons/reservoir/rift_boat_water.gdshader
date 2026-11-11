shader_type canvas_item;
uniform float waterline=.946;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float submerged=step(waterline,UV.y);
 c.rgb=mix(c.rgb,c.rgb*vec3(.68,.51,.92),submerged*.55);
 c.a*=1.0-submerged*.18;
 COLOR=c;
}
