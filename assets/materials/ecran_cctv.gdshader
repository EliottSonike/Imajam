shader_type spatial;
render_mode unshaded;

// Image d'écran de surveillance : grain, lignes, balayage et petit voyant REC.
uniform float allume : hint_range(0.0, 1.0) = 1.0;
uniform float graine = 0.0;
uniform vec3 teinte : source_color = vec3(0.55, 0.85, 0.75);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME + graine * 17.0;
	float base = 0.16 + 0.1 * (1.0 - uv.y);
	float grain = hash(floor(uv * vec2(160.0, 120.0)) + floor(t * 24.0)) * 0.12;
	float lignes = 0.85 + 0.15 * sin(uv.y * 240.0 + t * 6.0);
	float balayage = 0.92 + 0.08 * smoothstep(0.0, 0.04, abs(fract(uv.y + t * 0.15) - 0.5));
	float bords = smoothstep(0.0, 0.08, uv.x) * smoothstep(0.0, 0.08, 1.0 - uv.x)
		* smoothstep(0.0, 0.08, uv.y) * smoothstep(0.0, 0.08, 1.0 - uv.y);
	float rec = step(distance(uv, vec2(0.92, 0.1)), 0.022) * step(0.5, fract(t * 0.8));
	vec3 col = teinte * (base + grain) * lignes * balayage * mix(0.6, 1.0, bords);
	col += vec3(0.9, 0.05, 0.05) * rec;
	ALBEDO = col * allume;
}
