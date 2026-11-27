shader_type canvas_item;
// 정수 픽셀 단위로만 줄을 밀어 물결·글리치를 만들고, 색을 돌리고, 흰빛을 섞는다(확대·보간 없음).
uniform float amp = 0.0;
uniform float tm = 0.0;
uniform float glitch = 0.0;
uniform float seed = 0.0;
uniform float hue = 0.0;
uniform float white = 0.0;
uniform vec3 area = vec3(0.0, 0.0, 0.0);
uniform vec2 size = vec2(360.0, 640.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 px = floor(UV * size);
	float off = floor(sin(px.y * (area.z > 0.0 ? 0.45 : 0.13) + tm * (area.z > 0.0 ? 2.2 : 5.0)) * amp + 0.5);
	if (area.z > 0.0 && distance(px, area.xy) > area.z) off = 0.0;
	float band = floor(px.y / 10.0);
	if (hash(vec2(band, seed)) < glitch) off += floor((hash(vec2(band, seed + 7.0)) - 0.5) * 30.0);
	vec2 uv = vec2(clamp(px.x + off, 0.0, size.x - 1.0) + 0.5, px.y + 0.5) / size;
	vec4 c = texture(TEXTURE, uv);
	float a = hue; float cs = cos(a); float sn = sin(a);
	mat3 m = mat3(
		vec3(0.299 + 0.701 * cs + 0.168 * sn, 0.299 - 0.299 * cs - 0.328 * sn, 0.299 - 0.3 * cs + 1.25 * sn),
		vec3(0.587 - 0.587 * cs + 0.33 * sn, 0.587 + 0.413 * cs + 0.035 * sn, 0.587 - 0.588 * cs - 1.05 * sn),
		vec3(0.114 - 0.114 * cs - 0.497 * sn, 0.114 - 0.114 * cs + 0.292 * sn, 0.114 + 0.886 * cs - 0.203 * sn));
	c.rgb = clamp(m * c.rgb, 0.0, 1.0);
	c.rgb = mix(c.rgb, vec3(1.0), white);
	COLOR = c;
}
