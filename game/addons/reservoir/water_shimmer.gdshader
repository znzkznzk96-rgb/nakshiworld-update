shader_type canvas_item;
render_mode blend_add;

// 마을 물 위에 얹는 도트 반짝임: 굵은 도트 격자에 맞춰 움직이는 잔물결 줄과 깜빡이는 반짝 점.
// 좌표는 물 시작선(shore)에서 아래로 잰 거리라 깊이에 따라 줄 간격이 달라지고, scroll은 물 그림과 같이 움직인다.
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 3.0;
uniform float scroll = 0.0;
uniform float strength : hint_range(0.0, 2.0) = 0.4;
uniform float sparkle_threshold : hint_range(0.8, 0.999) = 0.993;
uniform vec4 tint_color : source_color = vec4(0.72, 0.95, 1.0, 1.0);

varying vec2 wp;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	wp = VERTEX;
}

void fragment() {
	vec2 q = floor(vec2(wp.x + scroll, wp.y) / pixel_size);
	float d = q.y;
	float x = q.x;
	float t = TIME;

	// 가로로 긴 잔물결 줄(줄 사이는 깊을수록 벌어진다). 끊어진 조각이 천천히 흐른다.
	float lane = d * 0.55 + sin(x * 0.11 + t * 0.7) * 0.9;
	float line_wave = sin(lane * 2.4 - t * 1.1);
	float ridge = smoothstep(0.86, 0.99, line_wave);
	float seg = step(0.15, sin(x * 0.07 + d * 0.31 + t * 0.45 + sin(d * 0.9) * 1.7));
	float depth_fade = clamp(0.45 + d * 0.012, 0.45, 1.0);   // 먼 물은 흐리게
	float streak = ridge * seg * 0.55 * depth_fade;

	// 칸 단위 반짝 점(깜빡임). 드물게만 켜진다.
	float r = hash21(vec2(x, d));
	float tw = 0.5 + 0.5 * sin(t * 3.2 + r * 40.0);
	float spark = step(sparkle_threshold, r) * tw;

	float intensity = clamp(streak + spark * 0.9, 0.0, 1.0) * strength;
	COLOR = vec4(tint_color.rgb * intensity, 1.0);
}
