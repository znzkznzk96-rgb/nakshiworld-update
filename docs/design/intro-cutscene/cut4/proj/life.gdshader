shader_type canvas_item;
// 배경 살리기: 등불·창문 깜빡임, 수면 달빛 반짝임, 달 주위 은은한 빛(모두 도트 단위, 보간 없음).
uniform float tm = 0.0;
uniform vec3 moon = vec3(180.0, 110.0, 40.0);
uniform vec4 water = vec4(0.0, 9999.0, 0.0, 0.0);   // x0, y0, x1, y1
uniform float block = 1.0;
uniform float dim = 0.0;
uniform vec2 size = vec2(360.0, 640.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * size);
	px = floor(px / block) * block + floor(block / 2.0);
	vec4 c = texture(TEXTURE, (px + 0.5) / size);
	// 등불·창문: 따뜻한 밝은 색만 칸마다 다른 박자로 일렁임
	float warm = step(0.62, c.r) * step(0.38, c.g) * step(c.b, 0.55) * step(0.22, c.r - c.b);
	vec2 cell = floor(px / 8.0);
	float h = hash(cell);
	float f = 0.86 + 0.14 * sin(tm * (2.5 + h * 4.0) + h * 6.28);
	if (hash(cell + floor(tm * 7.0)) > 0.985) f = 0.7;
	c.rgb *= mix(1.0, f, warm);
	// 수면 반짝임: 물 영역의 밝은 달빛 도트만 잠깐씩 하얗게
	float lum = dot(c.rgb, vec3(0.33));
	if (px.x >= water.x && px.y >= water.y && px.x <= water.z && px.y <= water.w && lum > 0.5) {
		float s = step(0.9, hash(px + floor(tm * 5.0) * 13.0));
		c.rgb = mix(c.rgb, vec3(1.0), s * 0.75);
	}
	// 달 주위 은은한 빛(계단식)
	float d = distance(px, moon.xy);
	float g = (1.0 - smoothstep(moon.z, moon.z * 2.4, d)) * step(moon.z, d);
	g = floor(g * 6.0) / 6.0 * (0.07 + 0.03 * sin(tm * 1.3));
	c.rgb += vec3(0.65, 0.75, 1.0) * g;
	c.rgb *= (1.0 - dim);
	COLOR = c;
}
