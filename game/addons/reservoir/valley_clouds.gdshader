shader_type canvas_item;
uniform sampler2D cloud_tex : filter_linear;
uniform sampler2D cloud_tall : filter_linear;
uniform sampler2D cloud_wisp : filter_linear;
uniform float elapsed = 0.0;
vec4 sample_cloud(sampler2D tex, vec2 p, vec2 center, vec2 size) {
 vec2 uv=(p-center)/size+vec2(0.5);
 float inside=step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
 vec4 c=texture(tex,clamp(uv,vec2(0.0),vec2(1.0)));c.a*=inside;return c;
}
void fragment() {
 vec4 plate=texture(TEXTURE,UV);
 // Reject foreground cliff, moss and waterfall colors, keeping clouds behind them.
 float sky=step(0.66,plate.b)*step(0.14,plate.b-plate.g)*step(0.12,plate.g-plate.r)*(1.0-step(0.50,UV.y));
 vec4 a=sample_cloud(cloud_tex,UV,vec2(0.48+sin(elapsed*0.021)*0.11,0.165),vec2(0.23,0.047));
 vec4 b=sample_cloud(cloud_tall,UV,vec2(0.57+sin(elapsed*0.016+2.0)*0.06,0.265),vec2(0.20,0.041));
 vec4 c=sample_cloud(cloud_wisp,UV,vec2(0.53+sin(elapsed*0.013+4.0)*0.13,0.20),vec2(0.22,0.020));
 vec4 d=sample_cloud(cloud_tex,UV,vec2(0.70+sin(elapsed*0.018+1.0)*0.09,0.395),vec2(0.16,0.033));
 vec4 e=sample_cloud(cloud_wisp,UV,vec2(0.47+sin(elapsed*0.011+3.0)*0.1,0.285),vec2(0.16,0.015));
 vec4 outc=a;
 if(b.a>outc.a)outc=b;
 if(c.a>outc.a)outc=c;
 if(d.a>outc.a)outc=d;
 if(e.a>outc.a)outc=e;
 COLOR=vec4(mix(outc.rgb,vec3(0.90,0.97,1.0),0.72),outc.a*sky*0.65);
}
