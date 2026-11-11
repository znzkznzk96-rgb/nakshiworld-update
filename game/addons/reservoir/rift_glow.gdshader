shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float elapsed=0.0;
void fragment(){
 vec2 px=TEXTURE_PIXEL_SIZE*2.0;
 float core=texture(TEXTURE,UV).a;
 float edge=0.0;
 float halo=0.0;
 for(int i=0;i<8;i++){
  float a=float(i)*0.7853981634;
  vec2 direction=vec2(cos(a),sin(a));
  edge=max(edge,texture(TEXTURE,UV+direction*px*1.2).a);
  halo=max(halo,texture(TEXTURE,UV+direction*px*3.5).a);
 }
 float pulse=.70+.10*sin(elapsed*.65+UV.x*6.0)+.05*sin(elapsed*1.1-UV.y*17.0);
 vec3 light=mix(vec3(.72,.16,.98),vec3(.38,.95,1.0),core);
 float opacity=max(core*.96,max(edge*.82,halo*.14));
 COLOR=vec4(light,opacity*pulse);
}
