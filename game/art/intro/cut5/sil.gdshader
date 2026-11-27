shader_type canvas_item;
// 달 앞 실루엣: 몸은 어두운 남색으로 칠하고, 위쪽(달 쪽)으로 드러난 가장자리 1도트만 달빛으로.
uniform vec4 body : source_color = vec4(0.05, 0.06, 0.13, 1.0);
uniform vec4 rim : source_color = vec4(0.72, 0.82, 1.0, 1.0);
uniform float amount = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) { COLOR = vec4(0.0); }
	else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float up = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
		float ul = texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
		float ur = texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
		float edge = step(min(up, min(ul, ur)), 0.5);
		vec3 s = mix(body.rgb, rim.rgb, edge);
		COLOR = vec4(mix(c.rgb, s, amount), 1.0);
	}
}
