shader_type canvas_item;
render_mode unshaded, blend_add;
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
 vec3 light=vec3(.53,.11,.85)*halo*.15+vec3(.84,.22,.94)*edge*.48+vec3(.23,.84,1.0)*core*.80;
 COLOR=vec4(light*pulse,1.0);
}
