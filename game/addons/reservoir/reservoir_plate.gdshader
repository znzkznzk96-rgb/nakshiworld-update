shader_type canvas_item;
render_mode unshaded;
uniform float hour=12.0;
uniform float night=0.0;
uniform bool terrain_only=false;
float skyline(float x) {
    if(x<95.0)return mix(475.0,507.0,x/95.0);
    if(x<200.0)return mix(507.0,475.0,(x-95.0)/105.0);
    if(x<282.0)return mix(475.0,494.0,(x-200.0)/82.0);
    if(x<392.0)return mix(494.0,466.0,(x-282.0)/110.0);
    if(x<481.0)return mix(466.0,490.0,(x-392.0)/89.0);
    if(x<666.0)return mix(490.0,422.0,(x-481.0)/185.0);
    return mix(422.0,469.0,(x-666.0)/137.0);
}
float box(vec2 p,vec2 center,vec2 halfsize){return 1.0-step(0.0,max(abs(p.x-center.x)-halfsize.x,abs(p.y-center.y)-halfsize.y));}
void fragment(){
    vec2 sample_uv=UV;
    vec2 screen_ref=UV*vec2(540.0,1320.0);
    if(screen_ref.x>=151.0 && screen_ref.x<179.0 && screen_ref.y>=545.0 && screen_ref.y<655.0){sample_uv.x=(134.0+mod(screen_ref.x-151.0,14.0))/540.0;}
    vec4 raw=texture(TEXTURE,sample_uv);vec2 p=UV*vec2(803.0,1959.0);
    float panes=box(p,vec2(158.0,677.0),vec2(7.0,14.0))+box(p,vec2(9.0,670.0),vec2(10.0,14.0));
    raw.rgb=mix(raw.rgb,vec3(0.16,0.27,0.32),clamp(panes,0.0,1.0)*0.8);
    float dusk=smoothstep(16.0,18.5,hour)*(1.0-smoothstep(19.0,21.0,hour));
    vec3 tint=mix(vec3(1.0),vec3(0.28,0.36,0.59),night);
    raw.rgb*=mix(tint,vec3(1.02,0.72,0.64),dusk*0.25);
    if(terrain_only)raw.a*=step(skyline(p.x),p.y);
    COLOR=raw;
}
