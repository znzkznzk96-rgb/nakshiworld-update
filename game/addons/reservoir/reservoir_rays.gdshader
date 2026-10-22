shader_type canvas_item;
render_mode unshaded;
uniform float elapsed=0.0;
uniform float night=0.0;
void fragment(){
    float d=UV.y;
    float light=0.0;
    for(int i=0;i<3;i++){
        float k=float(i);
        float origin=0.18+k*0.31+sin(elapsed*0.12+k*1.8)*0.018;
        float center=origin+(origin-0.5)*d*0.19;
        float width=0.018+d*0.19;
        float delta=(UV.x-center)/width;
        light+=exp(-delta*delta*2.8)*(0.82+0.18*sin(elapsed*0.37+k*2.2));
    }
    // Continuous Gaussian fade: no visible fan boundaries.
    float depth_fade=smoothstep(0.0,0.07,d)*(1.0-smoothstep(0.2,1.0,d));
    float edge=smoothstep(0.0,0.08,UV.x)*(1.0-smoothstep(0.92,1.0,UV.x));
    COLOR=vec4(mix(vec3(0.62,0.92,0.87),vec3(0.55,0.69,0.96),night),light*depth_fade*edge*mix(0.075,0.025,night));
}
