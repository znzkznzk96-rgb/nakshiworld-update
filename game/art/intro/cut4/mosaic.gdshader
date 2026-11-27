shader_type canvas_item;
// 눈이 초점을 잡기 전의 흐릿함: 정수 크기의 도트 덩어리로만 뭉갠다(보간 없음).
uniform float block = 1.0;
uniform float dim = 0.0;
void fragment() {
	vec2 size = vec2(360.0, 640.0);
	vec2 px = floor(UV * size);
	px = floor(px / block) * block + floor(block / 2.0);
	vec4 c = texture(TEXTURE, (px + 0.5) / size);
	c.rgb *= (1.0 - dim);
	COLOR = c;
}
