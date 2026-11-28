shader_type canvas_item;
// 달만 밝히기: 달 원 안은 밝기를 올리고, 바깥은 계단식으로 은은하게 번짐(흐림 없음).
uniform vec3 moon = vec3(180.0, 180.0, 168.0);
uniform float boost = 1.0;
uniform float tm = 0.0;
uniform vec2 size = vec2(360.0, 640.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * size);
	vec4 c = texture(TEXTURE, (px + 0.5) / size);
	float d = distance(px, moon.xy);
	if (d < moon.z) c.rgb = min(c.rgb * boost, vec3(1.0));
	float g = (1.0 - smoothstep(moon.z, moon.z * 1.45, d)) * step(moon.z, d);
	g = floor(g * 5.0) / 5.0 * (0.05 + 0.12 * (boost - 1.0) / 0.4);
	c.rgb += vec3(0.6, 0.7, 1.0) * g;
	// 수면 달빛 반짝임
	if (px.y > 450.0 && dot(c.rgb, vec3(0.33)) > 0.5) c.rgb = mix(c.rgb, vec3(1.0), step(0.9, hash(px + floor(tm * 5.0) * 13.0)) * 0.7);
	COLOR = c;
}
