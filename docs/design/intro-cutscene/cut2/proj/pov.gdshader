shader_type canvas_item;
// 시계 시점 바닥: 마른 바닥 → 물 찬 바닥(타일 틈에서 번짐) + 다리에 수면선(종아리까지 차오름). 정수 픽셀 단위로만 바뀐다.
uniform sampler2D water_tex : filter_nearest;
uniform float grow = 0.0;
uniform float wl = -1.0;
uniform float bright = 1.0;
uniform float tm = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * vec2(360.0, 640.0));
	vec4 dry = texture(TEXTURE, UV);
	vec4 wet = texture(water_tex, UV);
	// 타일 틈(줄눈)에서 먼저 번지고, 번진 곳이 점점 넓어진다
	float s = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7854;
		vec2 d = vec2(cos(a), sin(a));
		s += step(dot(texture(TEXTURE, UV + d * 7.0 / vec2(360.0, 640.0)).rgb, vec3(0.3333)), 0.5);
		s += step(dot(texture(TEXTURE, UV + d * 15.0 / vec2(360.0, 640.0)).rgb, vec3(0.3333)), 0.5);
	}
	s = clamp(s / 8.0, 0.0, 1.0);
	float n = hash(floor(px / 6.0)) * 0.3 + (1.0 - s) * 0.7;
	float m = step(n, grow * 1.25 - 0.02);
	vec4 col = mix(dry, wet, m);
	bool leg = dry.r > dry.b + 0.02;
	if (wl > 0.0) {
		float wave = floor(sin(px.x * 0.30 + tm * 4.0) * 2.0);
		float line = wl + wave;
		if (leg && px.y < line) {
			col.rgb = mix(col.rgb, vec3(0.42, 0.78, 0.76), 0.5);
		}
		if (leg && abs(px.y - line) < 1.5) {
			col.rgb = vec3(0.80, 0.97, 0.95);
		}
	}
	COLOR = vec4(col.rgb * bright, 1.0);
}
