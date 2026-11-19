shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float wave = -1.0;
uniform float flash = 0.0;
uniform float blackout = 0.0;
uniform float invert = 0.0;
uniform vec2 center = vec2(0.5, 0.39);
uniform vec4 glint : source_color = vec4(1.0, 0.82, 0.32, 1.0);

void fragment() {
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 delta = (SCREEN_UV - center) * aspect;
	float radius = length(delta);
	float edge = 0.0;
	if (wave >= 0.0) {
		edge = (1.0 - smoothstep(0.008, 0.035, abs(radius - wave * 0.9))) * (1.0 - wave);
	}
	vec2 offset = delta / max(radius, 0.001) / aspect * edge * 0.018;
	vec3 rgb = texture(scene_tex, SCREEN_UV - offset).rgb;
	rgb = mix(rgb, 1.0 - rgb, invert);
	rgb = mix(rgb, vec3(0.025, 0.025, 0.10), blackout);
	rgb = mix(rgb, glint.rgb, clamp(flash + edge * 0.28, 0.0, 1.0));
	COLOR = vec4(rgb, 1.0);
}
