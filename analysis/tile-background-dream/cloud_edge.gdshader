shader_type canvas_item;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float fade=(1.0-smoothstep(0.62,1.0,UV.y*(64.0/44.0)))*smoothstep(0.0,0.055,UV.x)*(1.0-smoothstep(0.945,1.0,UV.x));
 COLOR=vec4(c.rgb,c.a*fade)*COLOR;
}
