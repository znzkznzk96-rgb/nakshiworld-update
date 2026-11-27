shader_type canvas_item;
// 도트 디더 전환: 직전 화면 사진을 4x4 체크무늬 순서대로 한 칸씩 지워 다음 장면이 드러나게(검정 없음).
uniform float k = 0.0;
void fragment() {
	vec2 p = mod(floor(UV * vec2(360.0, 640.0)), 4.0);
	int i = int(p.x) + int(p.y) * 4;
	float b[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	if ((b[i] + 0.5) / 16.0 < k) discard;
	COLOR = texture(TEXTURE, UV);
}
