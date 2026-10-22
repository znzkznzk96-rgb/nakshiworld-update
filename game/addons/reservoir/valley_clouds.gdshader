shader_type canvas_item;
uniform sampler2D cloud_tex : filter_nearest;
uniform float elapsed = 0.0;
float cloud_alpha(vec2 p, vec2 center, vec2 size) {
 vec2 uv = (p-center)/size+vec2(0.5);
 float inside = step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
 return texture(cloud_tex,clamp(uv,vec2(0.0),vec2(1.0))).a*inside;
}
void fragment() {
 vec4 plate = texture(TEXTURE,UV);
 float sky = step(0.66,plate.b)*step(0.14,plate.b-plate.g)*step(0.12,plate.g-plate.r)*(1.0-step(0.50,UV.y));
 float a = cloud_alpha(UV,vec2(fract(0.48+elapsed*0.003),0.14),vec2(0.26,0.027));
 float b = cloud_alpha(UV,vec2(fract(0.70+elapsed*0.002),0.335),vec2(0.19,0.020));
 COLOR = vec4(0.87,0.98,1.0,max(a,b)*sky*0.65);
}
