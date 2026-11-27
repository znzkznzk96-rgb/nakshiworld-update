shader_type canvas_item;
// 4x4 베이어 도트 디더로 팔·시계가 알갱이로 흩어지며 사라짐(정수 픽셀 단위)
uniform float k = 0.0;
const float B[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	ivec2 p = ivec2(mod(floor(FRAGCOORD.xy), 4.0));
	float th = (B[p.y * 4 + p.x] + 0.5) / 16.0;
	if (th < k) { COLOR.a = 0.0; }
}
