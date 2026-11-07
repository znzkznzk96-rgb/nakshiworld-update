shader_type canvas_item;
render_mode unshaded, blend_add;

// Reference: vertical UV flow + sine warp + texture sample + depth attenuation.
// The unwarped UV drives the silhouette, so noise never bends the entire shaft.
uniform float elapsed = -1.0;
uniform float speed : hint_range(0.1,5.0) = 0.8;
uniform float wave_freq : hint_range(1.0,50.0) = 15.0;
uniform float wave_amp : hint_range(0.001,0.1) = 0.015;
uniform float light_intensity : hint_range(0.0,2.0) = 0.7;
uniform float origin_x = 0.4;
uniform float slope_x = 0.0;
uniform float tip_width = 0.008;
uniform float bottom_width = 0.34;
uniform float ray_length = 0.85;
uniform float seed_offset = 0.0;
uniform vec4 light_tint : source_color = vec4(0.57,0.91,0.78,1.0);

void fragment() {
    float t = elapsed < 0.0 ? TIME : elapsed;
    // Quantized source-space UV keeps the final effect on the plate pixel grid.
    vec2 p = (floor(UV * vec2(801.0,750.0)) + 0.5) / vec2(801.0,750.0);
    float depth = p.y / max(ray_length,0.01);
    vec2 flow_uv = vec2(p.x * 4.0 + seed_offset, p.y * 0.55 - t * speed);
    flow_uv.x += sin(flow_uv.y * wave_freq + t * 2.0 + seed_offset) * wave_amp;
    float noise_a = texture(TEXTURE,flow_uv).r;
    float noise_b = texture(TEXTURE,flow_uv * vec2(0.47,0.61) + vec2(0.13,t*0.035)).r;
    float width_flutter = 0.90 + noise_b * 0.20;
    float center = origin_x + slope_x * p.y;
    float half_width = mix(tip_width,bottom_width,clamp(depth,0.0,1.0)) * 0.5 * width_flutter;
    float mask = 1.0-smoothstep(half_width*0.30,max(half_width,0.001),abs(p.x-center));
    float depth_fade = pow(max(1.0-depth,0.0),0.75) * smoothstep(0.0,0.035,depth);
    // Broad texture modulation rather than uniform opaque triangular bands.
    float texture_light = mix(0.68,1.0,smoothstep(0.18,0.82,noise_a)) * mix(0.88,1.04,noise_b);
    float alpha = mask * depth_fade * texture_light * light_intensity * 0.20;
    // Alpha is applied once. The reference multiplied tex_color.a twice.
    COLOR = vec4(light_tint.rgb,clamp(alpha,0.0,0.30));
}
