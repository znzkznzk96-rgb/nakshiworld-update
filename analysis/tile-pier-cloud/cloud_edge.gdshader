shader_type canvas_item;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float edge=smoothstep(0.0,0.06,UV.x)*(1.0-smoothstep(0.94,1.0,UV.x));
 vec3 soft=mix(c.rgb,vec3(0.91,0.89,1.0),0.65);
 COLOR=vec4(soft,c.a*edge)*COLOR;
}
