shader_type spatial;
render_mode unshaded;

// Écran de surveillance : image de la caméra (flux) en noir et blanc verdâtre,
// avec grain, lignes, balayage et petit voyant REC. Sans flux : neige seule.
uniform float allume : hint_range(0.0, 1.0) = 1.0;
uniform float graine = 0.0;
uniform vec3 teinte : source_color = vec3(0.55, 0.85, 0.75);
uniform sampler2D flux : source_color, filter_linear;
uniform float a_flux : hint_range(0.0, 1.0) = 0.0;
uniform float parasites : hint_range(0.0, 1.0) = 0.0; // neige au changement de caméra

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = vec2(1.0 - UV.x, UV.y); // la dalle est modélisée de dos : on remet l'image à l'endroit
	float t = TIME + graine * 17.0;

	// Léger décalage horizontal de ligne, plus fort pendant les parasites.
	float bande = hash(vec2(floor(uv.y * 90.0), floor(t * 12.0)));
	uv.x += (bande - 0.5) * (0.003 + parasites * 0.06);

	float base = 0.16 + 0.1 * (1.0 - uv.y);
	float grain = hash(floor(uv * vec2(160.0, 120.0)) + floor(t * 24.0));
	float lignes = 0.85 + 0.15 * sin(uv.y * 240.0 + t * 6.0);
	float balayage = 0.92 + 0.08 * smoothstep(0.0, 0.04, abs(fract(uv.y + t * 0.15) - 0.5));
	float bords = smoothstep(0.0, 0.08, uv.x) * smoothstep(0.0, 0.08, 1.0 - uv.x)
		* smoothstep(0.0, 0.08, uv.y) * smoothstep(0.0, 0.08, 1.0 - uv.y);

	vec3 neige = teinte * (base + grain * 0.12);
	vec3 img = texture(flux, clamp(uv, 0.0, 1.0)).rgb;
	float l = dot(img, vec3(0.299, 0.587, 0.114));
	vec3 camera = teinte * (pow(l, 0.85) * 1.5 + 0.03) + (grain - 0.5) * 0.06;
	vec3 col = mix(neige, camera, a_flux);
	col = mix(col, vec3(grain) * teinte * 1.2, parasites * 0.85);
	col *= lignes * balayage * mix(0.6, 1.0, bords);

	float rec = step(distance(vec2(1.0 - UV.x, UV.y), vec2(0.92, 0.1)), 0.022) * step(0.5, fract(t * 0.8));
	col += vec3(0.9, 0.05, 0.05) * rec;
	ALBEDO = col * allume;
}
