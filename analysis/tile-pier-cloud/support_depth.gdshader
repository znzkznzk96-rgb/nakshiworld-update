shader_type canvas_item;
uniform vec2 uv_min=vec2(0.0);
uniform vec2 uv_span=vec2(1.0);
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float depth=clamp((UV.y-uv_min.y)/uv_span.y,0.0,1.0);
 float fade=1.0-smoothstep(0.08,0.98,depth);
 vec3 water=mix(vec3(0.03,0.32,0.46),vec3(0.10,0.14,0.37),depth);
 vec3 submerged=mix(c.rgb,water,0.35+depth*0.55);
 COLOR=vec4(submerged,c.a*fade*0.88)*COLOR;
}
