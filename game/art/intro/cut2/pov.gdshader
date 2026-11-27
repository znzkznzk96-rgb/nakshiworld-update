shader_type canvas_item;
// 시계 시점 바닥: 마른 바닥 → 물 찬 바닥. 타일 틈(줄눈)과 부츠 둘레에서 물이 스며 나와 매끈한 물가 선으로 넓게 번진다.
// water_dist: 줄눈까지의 거리(0=줄눈). 번지는 앞쪽에 1~2도트 밝은 물가 선. 정수 픽셀 단위로만 바뀐다.
uniform sampler2D water_tex : filter_nearest;
uniform sampler2D water_dist : filter_nearest;
uniform float grow = 0.0;
uniform float wl = -1.0;
uniform float bright = 1.0;
uniform float tm = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * vec2(360.0, 640.0));
	vec4 dry = texture(TEXTURE, UV);
	// 수면 잔물결: 물 그림을 줄마다 1도트씩 좌우로 일렁이게(진폭 일정)
	float wob = floor(sin(px.y * 0.11 + tm * 2.4) * 1.0 + 0.5);
	vec4 wet = texture(water_tex, (vec2(clamp(px.x + wob, 0.0, 359.0), px.y) + 0.5) / vec2(360.0, 640.0));
	// 반사광 반짝임: 밝은 빛 무늬 도트만 잠깐씩 하얗게
	if (dot(wet.rgb, vec3(0.333)) > 0.62) wet.rgb = mix(wet.rgb, vec3(1.0), step(0.93, hash(px + floor(tm * 4.0) * 7.0)) * 0.45);
	float d = texture(water_dist, UV).r;
	// 물가 선이 살짝 일렁이게(2도트 단위로만 흔들림)
	d += (hash(floor(px / 3.0)) - 0.5) * 0.04 + sin(px.x * 0.09 + px.y * 0.05 + tm * 2.0) * 0.02;
	float front = grow * 1.08;
	bool leg = dry.r > dry.b + 0.02;
	vec4 col = dry;
	if (d < front) col = wet;
	// 젖어 가는 가장자리: 앞쪽 띠는 밝은 물가 선, 그 바로 바깥은 살짝 어두운 젖은 자국
	if (grow > 0.0 && grow < 0.98 && !leg) {
		if (d < front && d > front - 0.035) col.rgb = mix(wet.rgb, vec3(0.82, 0.97, 0.98), 0.55);
		else if (d >= front && d < front + 0.03) col.rgb = dry.rgb * 0.82;
	}
	if (wl > 0.0) {
		float wave = floor(sin(px.x * 0.30 + tm * 4.0) * 2.0);
		float line = wl + wave;
		if (leg && px.y < line) {
			col.rgb = mix(col.rgb, vec3(0.16, 0.52, 0.62), 0.55);
		}
		if (leg && abs(px.y - line) < 1.5) {
			col.rgb = vec3(0.80, 0.97, 0.95);
		}
	}
	COLOR = vec4(col.rgb * bright, 1.0);
}
