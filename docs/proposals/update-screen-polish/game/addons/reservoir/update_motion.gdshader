shader_type canvas_item;
render_mode unshaded;

uniform int effect = 0;
uniform float clock = 0.0;
uniform vec2 art_size = vec2(841.0, 1870.0);

float box_mask(vec2 p, vec4 bounds, float feather) {
	vec2 low = smoothstep(bounds.xy, bounds.xy + vec2(feather), p);
	vec2 high = 1.0 - smoothstep(bounds.zw - vec2(feather), bounds.zw, p);
	return low.x * low.y * high.x * high.y;
}

float ellipse(vec2 p, vec2 center, vec2 radius) {
	float d = length((p - center) / radius);
	return 1.0 - smoothstep(0.35, 1.0, d);
}

void fragment() {
	vec2 p = UV * art_size;
	vec2 sample_p = p;
	float mask = 0.0;
	vec3 extra = vec3(0.0);
	float brightness = 1.0;
	if (effect == 0) {
		// Only the title block floats. The logo and subtitle remain still.
		mask = box_mask(p, vec4(177.0, 333.0, 668.0, 506.0), 13.0);
		sample_p.y -= floor(sin(clock * 1.12) * 5.0 + 0.5) * mask;
		sample_p.x -= floor(sin(clock * 0.56) * 1.5 + 0.5) * mask;
		vec3 source = texture(TEXTURE, sample_p / art_size).rgb;
		float gold = smoothstep(0.52, 0.78, source.r) * smoothstep(0.37, 0.64, source.g);
		float sweep = exp(-pow((p.x - (160.0 + mod(clock * 65.0, 850.0))) / 34.0, 2.0));
		extra = vec3(0.10, 0.08, 0.04) * gold * sweep;
	} else if (effect == 1) {
		// Three water planes; equipment, cat, lanterns and text are excluded.
		float far_water = box_mask(p, vec4(0.0, 732.0, 841.0, 854.0), 8.0);
		far_water *= 1.0 - box_mask(p, vec4(127.0, 752.0, 351.0, 863.0), 3.0);
		far_water *= 1.0 - box_mask(p, vec4(608.0, 738.0, 705.0, 865.0), 3.0);
		far_water *= 1.0 - box_mask(p, vec4(704.0, 727.0, 756.0, 864.0), 3.0);
		far_water *= 1.0 - box_mask(p, vec4(520.0, 813.0, 604.0, 859.0), 3.0);
		float right_water = box_mask(p, vec4(761.0, 1130.0, 841.0, 1403.0), 10.0);
		float near_water = box_mask(p, vec4(216.0, 1668.0, 617.0, 1870.0), 12.0);
		near_water *= 1.0 - box_mask(p, vec4(273.0, 1701.0, 577.0, 1770.0), 6.0);
		mask = max(far_water, max(right_water, near_water));
		float wave = sin(p.y * 0.085 - clock * 1.65) * 2.8 + sin(p.y * 0.032 + clock * 0.8) * 1.3;
		sample_p.x += floor(wave + 0.5) * mask;
		brightness = 1.0 + 0.07 * sin(p.y * 0.11 - clock * 1.8);
	} else if (effect == 2) {
		// Sleeping cat: anchored paws, breathing torso, almost still face.
		mask = box_mask(p, vec4(130.0, 755.0, 350.0, 858.0), 6.0);
		float breath = 0.5 - 0.5 * cos(clock * 1.65347);
		float torso = 1.0 - smoothstep(234.0, 273.0, p.x);
		float height_scale = 1.0 + 0.048 * breath * torso;
		sample_p.y = 849.0 + (p.y - 849.0) / height_scale;
		sample_p.x = 239.0 + (p.x - 239.0) / (1.0 + 0.014 * breath * torso);
		sample_p = floor(sample_p + vec2(0.5));
	} else if (effect == 3) {
		float small_lamp = ellipse(p, vec2(655.0, 784.0), vec2(40.0, 58.0));
		float large_lamp = ellipse(p, vec2(80.0, 1567.0), vec2(79.0, 116.0));
		float a = 0.58 + 0.24 * sin(clock * 5.1) + 0.13 * sin(clock * 11.3 + 1.1);
		float b = 0.58 + 0.23 * sin(clock * 4.3 + 2.0) + 0.14 * sin(clock * 9.7);
		mask = max(small_lamp, large_lamp);
		vec3 source = texture(TEXTURE, UV).rgb;
		float warm = smoothstep(0.28, 0.72, source.r) * (1.0 - smoothstep(0.7, 1.0, source.b));
		extra = vec3(0.23, 0.13, 0.025) * warm * (small_lamp * a + large_lamp * b);
		brightness = 1.0 + warm * (-0.38 + 0.76 * (small_lamp * a + large_lamp * b));
	} else if (effect == 4) {
		// Existing stars only: independent phases, no twinkle over text or moon.
		vec2 stars[12] = {vec2(136,52),vec2(284,91),vec2(532,33),vec2(786,44),vec2(214,178),vec2(356,177),vec2(462,166),vec2(499,219),vec2(593,266),vec2(727,376),vec2(796,480),vec2(148,515)};
		float light = 0.0;
		for (int i=0; i<12; i++) {
			float area = ellipse(p, stars[i], vec2(14.0));
			float pulse = pow(0.5+0.5*sin(clock*(1.5+float(i)*0.07)+float(i)*2.4), 3.0);
			mask = max(mask, area);
			light += area * pulse;
		}
		vec3 source = texture(TEXTURE,UV).rgb;
		float star_pixel = smoothstep(0.26,0.65,max(source.r,max(source.g,source.b)));
		brightness = 1.0 + star_pixel*(-0.60 + 1.35*light);
		extra = vec3(0.04,0.045,0.04)*light;
	}
	vec4 color = texture(TEXTURE, sample_p / art_size);
	// Replace the baked-in second shoreline below the helmet with continuous water.
	// No shifting of the helmet, rope, receiver frame or foreground dock.
	if (effect == 1) {
		float left = mix(792.0,773.0,smoothstep(1092.0,1135.0,p.y));
		left = mix(left,756.0,smoothstep(1135.0,1180.0,p.y));
		left = mix(left,752.0,smoothstep(1180.0,1320.0,p.y));
		left = mix(left,759.0,smoothstep(1320.0,1414.0,p.y));
		float repair = step(left,p.x) * smoothstep(1090.0,1100.0,p.y) * (1.0-step(1414.0,p.y));
		// Sparse long horizontal ripples, no checker pattern or duplicate shoreline.
		float row = floor(p.y/4.0);
		float seed = fract(sin(row*127.1)*43758.5453);
		float along = fract((p.x+seed*170.0-clock*2.0)/143.0);
		float ripple = step(0.83,seed)*step(0.23,along)*(1.0-step(0.79,along));
		float depth = smoothstep(1090.0,1414.0,p.y);
		vec3 water = mix(vec3(0.029,0.078,0.122),vec3(0.021,0.057,0.089),depth);
		water += vec3(0.018,0.035,0.047)*ripple;

		color.rgb = mix(color.rgb*brightness+extra,water,repair);
		mask = max(mask,repair);
		COLOR = vec4(color.rgb,mask);
	} else {
		COLOR = vec4(color.rgb * brightness + extra, mask);
	}
}
