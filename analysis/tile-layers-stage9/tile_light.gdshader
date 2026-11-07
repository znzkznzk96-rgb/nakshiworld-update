shader_type canvas_item;
render_mode unshaded, blend_add;

// Procedural anisotropic 2D noise. No sampled light texture, apex or cone mask.
uniform float elapsed = -1.0;
uniform float seed_offset = 0.0;
uniform float sun_shear = 0.0;
uniform float light_intensity : hint_range(0.0,2.0) = 1.0;
uniform vec4 light_tint : source_color = vec4(0.57,0.92,0.80,1.0);
float hash2(vec2 p) {
    return fract(sin(dot(p,vec2(127.1,311.7)) + seed_offset) * 43758.5453);
}
float noise2(vec2 p) {
    vec2 cell=floor(p);
    vec2 f=fract(p);
    vec2 u=f*f*(3.0-2.0*f);
    return mix(mix(hash2(cell),hash2(cell+vec2(1.0,0.0)),u.x),
               mix(hash2(cell+vec2(0.0,1.0)),hash2(cell+vec2(1.0,1.0)),u.x),u.y);
}
float fbm(vec2 p) {
    return noise2(p)*0.62 + noise2(p*2.03+vec2(7.1,3.9))*0.27
         + noise2(p*4.07+vec2(19.4,11.3))*0.11;
}
void fragment() {
    float t=elapsed<0.0?TIME:elapsed;
    vec2 p=(floor(UV*vec2(801.0,750.0))+0.5)/vec2(801.0,750.0);
    // Shear translates every depth equally in direction; it never widens a band.
    float x=p.x-sun_shear*p.y;
    float drift=t*0.028;
    float warp=(noise2(vec2(x*4.0+drift,p.y*0.32-t*0.015))-0.5)*0.017;
    // High horizontal frequency, very low vertical frequency = upright ribbons.
    float broad=fbm(vec2((x+warp)*24.0+drift,p.y*0.36-t*0.035));
    float fine=fbm(vec2((x+warp)*59.0-drift*0.65,p.y*0.55-t*0.024)+vec2(23.7,5.1));
    float streaks=smoothstep(0.46,0.82,broad)*0.78
                 +smoothstep(0.57,0.86,fine)*0.22;
    float envelope=0.70+0.30*noise2(vec2(x*7.0-t*0.025,p.y*1.1+t*0.018));
    float depth_fade=pow(max(1.0-p.y/0.94,0.0),1.25);
    float entrance=smoothstep(0.0,0.02,p.y);
    float alpha=streaks*envelope*depth_fade*entrance*light_intensity*0.24;
    COLOR=vec4(light_tint.rgb,clamp(alpha,0.0,0.24));
}
