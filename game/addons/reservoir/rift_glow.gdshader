shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float elapsed=0.0;
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float mask=c.a;
 float pulse=.30+.22*sin(elapsed*1.3+UV.x*6.0)+.14*sin(elapsed*.7-UV.y*17.0);
 vec3 tint=mix(vec3(.65,.22,1.0),vec3(.24,.66,1.0),.5+.5*sin(elapsed*.45+UV.x*4.0));
 COLOR=vec4(tint,mask*max(.10,pulse));
}
