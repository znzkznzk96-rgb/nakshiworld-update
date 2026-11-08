shader_type canvas_item;
render_mode blend_add,unshaded;
uniform float night_strength : hint_range(0.0,1.0) = 0.0;
uniform int profile = 0;
uniform vec2 lantern_uv=vec2(-2.0);
uniform vec2 lantern_span=vec2(0.1);
uniform vec2 fight_uv=vec2(-2.0);
uniform float fighting=0.0;
float soft_pool(vec2 uv,vec2 center,vec2 spread){
 vec2 p=(uv-center)/spread;
 return exp(-dot(p,p)*2.0);
}
void fragment(){
 float light=0.0;
 vec3 tint;
 if(profile==0){
  // Soft moonlit water, the reverse waterfall, and the edge of the fishing ledge.
  light=soft_pool(UV,vec2(0.81,0.39),vec2(0.07,0.21))*0.58;
  light+=soft_pool(UV,vec2(0.77,0.555),vec2(0.24,0.033))*0.86;
  light+=soft_pool(UV,vec2(0.24,0.535),vec2(0.16,0.048))*0.50;
  light+=soft_pool(UV,vec2(0.63,0.65),vec2(0.25,0.17))*0.18;
  tint=vec3(0.36,0.67,1.0);
 }else{
  // Lavender light stays near the pier and waterline, leaving deep water dark.
  light=soft_pool(UV,vec2(0.25,0.455),vec2(0.18,0.032))*0.85;
  light+=soft_pool(UV,vec2(0.72,0.495),vec2(0.40,0.024))*0.80;
  light+=soft_pool(UV,vec2(0.77,0.36),vec2(0.17,0.12))*0.28;
  light+=soft_pool(UV,vec2(0.45,0.60),vec2(0.30,0.12))*0.15;
  tint=vec3(0.73,0.43,1.0);
 }
 float surface=profile==0?0.565:0.498;
 float water=smoothstep(surface,surface+0.05,UV.y);
 float quiet=1.0-fighting*soft_pool(UV,fight_uv,vec2(0.20,0.10))*0.6;
 float ambient=water*(profile==0?0.30:0.25)*night_strength;
 float biological=(soft_pool(UV,vec2(0.23,0.84),vec2(0.20,0.12))*0.10+soft_pool(UV,vec2(0.77,0.72),vec2(0.17,0.14))*0.09)*night_strength*quiet;
 float cool=min(light*night_strength*0.38,0.38)+ambient+biological;
 float warm_halo=soft_pool(UV,lantern_uv,lantern_span)*0.45;
 float warm_core=soft_pool(UV,lantern_uv,lantern_span*0.10)*0.85;
 float warm=(warm_halo+warm_core)*night_strength;
 float alpha=max(cool+warm,0.00001);
 vec3 emission=tint*cool+vec3(0.65,1.0,0.93)*warm;
 COLOR=vec4(emission/alpha,alpha);
}
