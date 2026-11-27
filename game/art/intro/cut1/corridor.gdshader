shader_type canvas_item;
// 소실점 기준 깊이(r)마다 형광등 하나가 그 구간을 밝힌다
uniform float on[9];
uniform float rr[9];
uniform vec2 vp = vec2(192.0, 300.0);
uniform vec2 tex_size = vec2(384.0, 688.0);
void fragment(){
	vec4 c = texture(TEXTURE, UV);
	vec2 p = UV * tex_size;
	float dx = abs(p.x - vp.x) / 192.0;
	float dy = p.y < vp.y ? (vp.y - p.y) / 300.0 : (p.y - vp.y) / 388.0;
	float r = max(max(dx, dy), 0.001);
	float lit = 0.0;
	for (int i = 0; i < 9; i++) {
		float d = (log(r) - log(rr[i])) / 0.30;
		lit += on[i] * exp(-d * d);
	}
	if (r < rr[8]) { lit += on[8]; }   // 가장 먼 등 너머(복도 끝)도 함께 밝힌다
	lit = clamp(lit, 0.0, 1.0);
	// 가까운 등 아래(화면 아래쪽 바닥)도 첫 등이 비춘다
	vec3 dark = c.rgb * 0.02;
	COLOR = vec4(mix(dark, c.rgb, lit), c.a);
}
