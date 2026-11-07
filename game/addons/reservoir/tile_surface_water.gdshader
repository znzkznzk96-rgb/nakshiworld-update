shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float elapsed = 0.0;
uniform float speed : hint_range(0.1,5.0) = 1.0;
uniform float wave_strength : hint_range(0.001,0.1) = 0.012;
uniform float frequency : hint_range(1.0,50.0) = 20.0;
uniform float flow_direction = 1.0;
uniform float opacity = 0.65;
uniform vec4 water_tint : source_color = vec4(0.53,0.95,0.86,1.0);
void fragment() {
    vec2 p=(floor(UV*vec2(460.0,132.0))+0.5)/vec2(460.0,132.0);
    float t=elapsed*speed;
    vec2 uv=p;
    float wave1=sin(p.x*frequency+t);
    float wave2=cos(p.y*(frequency*0.5)-t*1.5);
    uv.x+=flow_direction*t*0.028+wave1*wave_strength;
    uv.y+=wave2*wave_strength;
    // Repeat only horizontally; the water-window edges must never wrap upward.
    uv.x=fract(uv.x);
    uv.y=clamp(uv.y,0.0,1.0);
    vec4 sample_color=texture(TEXTURE,uv);
    float edge=smoothstep(0.0,0.12,p.y)*(1.0-smoothstep(0.87,1.0,p.y));
    float shimmer=0.70+0.30*sin(p.x*17.0+p.y*9.0-t*0.75);
    COLOR=vec4(water_tint.rgb,sample_color.a*opacity*edge*shimmer);
}
