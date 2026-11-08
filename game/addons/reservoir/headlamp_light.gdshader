shader_type canvas_item;
render_mode blend_add,unshaded;
uniform vec2 lamp_position=vec2(-1000.0);
uniform vec2 viewport_size=vec2(270.0,540.0);
uniform float night_strength=0.0;
void fragment(){
 vec2 p=UV*viewport_size-lamp_position;
 vec2 fall=p/vec2(36.0,43.0);
 float irradiance=exp(-dot(fall,fall)*1.6);
 vec4 original=texture(TEXTURE,UV);
 // Only existing opaque actor pixels receive surface light. Legs remain in shade.
 vec3 surface=original.rgb*original.a*vec3(0.70,1.0,0.91)*irradiance*0.32;
 vec2 haze=p/vec2(35.0,32.0);
 float bloom=exp(-dot(haze,haze)*2.2)*0.24;
 vec2 front=(p-vec2(13.0,4.0))/vec2(36.0,23.0);
 bloom+=exp(-dot(front,front)*2.0)*0.065;
 float core=exp(-dot(p,p)/3.2)*0.90;
 // Haze stays mostly in the air; avoid bleaching opaque face pixels.
 bloom*=1.0-original.a*0.85;
 vec3 emission=surface+vec3(0.68,1.0,0.89)*(bloom+core);
 float alpha=max(original.a*irradiance*0.70,bloom+core);
 COLOR=vec4(emission/max(alpha,0.00001),min(alpha*night_strength,1.0));
}
