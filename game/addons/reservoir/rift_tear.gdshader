shader_type canvas_item;
render_mode unshaded;
uniform float elapsed=0.0;
varying vec2 local_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){local_position=VERTEX;}
void fragment(){
 vec2 p=floor(local_position);
 float cloud=noise(p*vec2(.028,.11)+vec2(-elapsed*.12,elapsed*.025));
 float wisps=noise(p*vec2(.06,.19)+vec2(-elapsed*.22,0.0));
 float energy=smoothstep(.36,.82,cloud)*(.6+.4*wisps);
 vec3 color=mix(vec3(.025,.035,.16),vec3(.04,.55,.75),energy);
 color=mix(color,vec3(.23,.91,1.0),pow(energy,3.0)*.80);
 float star=step(.994,hash(floor(p*.5)))*(.45+.25*sin(elapsed+p.x));
 COLOR=vec4(color+vec3(.25,.55,.80)*star,1.0);
}
