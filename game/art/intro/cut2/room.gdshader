shader_type canvas_item;
// 타일 방: 불이 꺼진 어둠 + 문틀 안쪽(복도 빛) 밝기 + 형광등 켜짐(amb)
uniform float amb = 0.0;
uniform float glow = 0.0;
uniform vec4 door = vec4(160.0, 276.0, 224.0, 393.0);
uniform vec2 tex_size = vec2(384.0, 688.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = floor(UV * tex_size);
	vec3 col = mix(c.rgb * 0.035, c.rgb, clamp(amb, 0.0, 1.0));
	if (p.x >= door.x && p.x < door.z && p.y >= door.y && p.y < door.w) {
		col = mix(col, c.rgb, glow);
	}
	// 문 앞 바닥에 번지는 복도 빛
	float d = length((p - vec2(192.0, 420.0)) * vec2(0.8, 1.3)) / 120.0;
	col += c.rgb * vec3(1.0, 0.85, 0.45) * glow * exp(-d * d * 2.5) * 0.35 * (1.0 - clamp(amb, 0.0, 1.0));
	COLOR = vec4(col, 1.0);
}
