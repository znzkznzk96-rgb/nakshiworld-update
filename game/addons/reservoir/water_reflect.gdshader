shader_type canvas_item;
// 마을 물: 매끈한 반사 물. 물 시작선 위의 하늘·산·구름을 뒤집어 비추고, 굴곡·깊이 색·햇빛 줄·물가 거품을 더한다.
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float shore_v = 0.5;                       // 물 시작선의 화면 세로 위치(0~1)
uniform vec2 v_per_px = vec2(0.003, 0.0015);       // 로컬 1px이 화면 UV에서 차지하는 크기
uniform float scroll = 0.0;                        // 화면 이동량(물결이 그림과 함께 따라가게)
uniform vec4 shallow_color : source_color = vec4(0.18, 0.66, 0.76, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.2, 0.34, 1.0);
uniform float depth_px = 300.0;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	float d = lp.y;
	float x = lp.x + scroll;
	float t = TIME;
	float depth = smoothstep(0.0, 1.0, clamp(d / depth_px, 0.0, 1.0));

	// 일렁이는 굴곡(여러 파장을 겹침). 깊이(가까울수록)가 커질수록 크게 흔들린다.
	float w1 = sin(x * 0.045 + t * 0.9 + d * 0.06);
	float w2 = sin(x * 0.11 - t * 1.3 + d * 0.13);
	float w3 = sin(x * 0.021 + d * 0.025 - t * 0.5);
	float wob = w1 * 0.5 + w2 * 0.3 + w3 * 0.2;

	// 반사: 물 시작선을 기준으로 위쪽을 뒤집어 읽는다(멀수록 압축 + 굴곡만큼 흔들림).
	float src = d * 0.5 + wob * (1.5 + d * 0.035);
	vec2 ruv = vec2(SCREEN_UV.x + wob * v_per_px.x * (1.2 + d * 0.025), shore_v - max(src, 0.0) * v_per_px.y);
	vec3 refl = texture(screen_tex, ruv).rgb;

	vec3 base = mix(shallow_color.rgb, deep_color.rgb, depth);
	vec3 col = mix(base, refl * vec3(0.9, 1.0, 1.04), mix(0.62, 0.16, depth));

	// 햇빛 줄: 가로로 길고 천천히 끊기며 흐른다.
	float streak = sin(x * 0.05 + sin(d * 0.13 + t * 0.7) * 1.4 - t * 0.35) * sin(d * 0.3 - t * 0.9 + w3);
	float glint = smoothstep(0.78, 0.98, streak) * (1.0 - depth * 0.55);
	col += vec3(0.85, 0.96, 1.0) * glint * 0.32;

	// 은은한 큰 물결 명암
	col += (wob * 0.5 + 0.5 - 0.5) * 0.05;

	// 물가 거품
	float foam = smoothstep(7.0, 0.0, d + wob * 2.0);
	col = mix(col, vec3(0.92, 0.98, 1.0), foam * 0.6);

	COLOR = vec4(col, 1.0);
}
