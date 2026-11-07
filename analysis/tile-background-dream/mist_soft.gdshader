shader_type canvas_item;
render_mode blend_add;
void fragment(){
 float a=0.0;
 for(int x=-2;x<=2;x++)for(int y=-2;y<=2;y++)a+=texture(TEXTURE,UV+vec2(float(x),float(y))*TEXTURE_PIXEL_SIZE*1.5).a;
 a/=25.0;
 COLOR=vec4(vec3(0.87,0.85,1.0),a*0.7)*COLOR;
}
