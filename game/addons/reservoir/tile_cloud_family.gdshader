shader_type canvas_item;
uniform sampler2D plate:filter_nearest;
uniform vec2 cloud_pos=vec2(400.0,300.0);
uniform vec2 cloud_size=vec2(200.0,40.0);
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float edge=smoothstep(0.0,0.04,UV.x)*(1.0-smoothstep(0.96,1.0,UV.x))*smoothstep(0.0,0.14,UV.y);
 vec3 behind=texture(plate,(cloud_pos+(UV-vec2(0.5))*cloud_size)/vec2(801.0,1962.0)).rgb;
 float sky=smoothstep(0.67,0.84,behind.g)*smoothstep(0.65,0.82,behind.b)*smoothstep(0.08,0.28,behind.r);
 vec3 soft=mix(c.rgb,vec3(0.91,0.89,1.0),0.65);
 COLOR=vec4(soft,c.a*edge*sky)*COLOR;
}
