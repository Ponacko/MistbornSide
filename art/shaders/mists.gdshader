shader_type canvas_item;
// The mists (DESIGN.md 12.3): two scrolling noise layers advected by a flow
// that swirls toward burning Allomancers and parts around spiked beings,
// pooled near floors and masked out of interiors by a baked density map.
// Mirrors MistField on the CPU.

uniform sampler2D noise_a : repeat_enable, filter_linear;
uniform sampler2D noise_b : repeat_enable, filter_linear;
uniform sampler2D density_map : filter_linear;
uniform vec2 map_origin;
uniform vec2 map_size = vec2(1.0);
uniform vec2 cam_origin;
uniform float cam_scale = 1.0;
uniform float mist_time;
uniform vec2 drift = vec2(7.0, 0.8);
uniform vec4 attractors[8];
uniform int attractor_count = 0;
uniform vec4 repellers[8];
uniform int repeller_count = 0;
uniform float thickness = 0.35;
// Tin thins the mists for the viewer; Steelsight tints them bluer.
uniform float thin = 0.0;
uniform float blue_tint = 0.0;
// Vin's visible radius (tin triples it): beyond it the night closes in.
uniform vec2 vision_center;
uniform float vision_radius = 100000.0;
uniform vec4 mist_color : source_color = vec4(0.46, 0.50, 0.60, 1.0);
uniform vec4 steel_color : source_color = vec4(0.45, 0.58, 0.9, 1.0);
const float ATTRACT_RADIUS = 90.0;

mat2 rot(float a) {
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, s), vec2(-s, c));
}

void fragment() {
	vec2 world = cam_origin + FRAGCOORD.xy * cam_scale;
	vec2 p = world;
	float gather = 0.0;
	for (int i = 0; i < attractor_count; i++) {
		vec2 a = attractors[i].xy;
		vec2 d = p - a;
		float r2 = dot(d, d);
		float f = attractors[i].z * exp(-r2 / (2.0 * ATTRACT_RADIUS * ATTRACT_RADIUS));
		// A bounded twist that breathes with the swirl phase: the mists bend
		// around the Allomancer and thicken toward her without shearing
		// into a whirlpool over time.
		d = rot(f * (1.1 + 0.35 * sin(attractors[i].w))) * d;
		d *= 1.0 + 0.35 * f;
		p = a + d;
		gather += f;
	}
	float n1 = texture(noise_a, (p + drift * mist_time) / 320.0).r;
	float n2 = texture(noise_b, (p + vec2(-drift.x * 0.6, drift.y * 1.5) * mist_time) / 170.0).r;
	float n = n1 * 0.65 + n2 * 0.35;
	// A near-camera layer: coarse wisps that slide faster than the world as
	// the camera moves, so the fog has depth between Vin and the viewer.
	vec2 near_p = world * 0.6 + cam_origin * 0.5 + vec2(drift.x * 1.8, drift.y) * mist_time;
	float near = smoothstep(0.55, 0.9, texture(noise_b, near_p / 260.0).r);

	vec2 muv = (world - map_origin) / map_size;
	float pool = 0.0;
	float open_air = 1.0;
	if (muv.x >= 0.0 && muv.y >= 0.0 && muv.x <= 1.0 && muv.y <= 1.0) {
		vec4 dm = texture(density_map, muv);
		pool = dm.r;
		open_air = dm.g;
	}

	// Wisps, not a blanket: high-contrast noise, thin in open air, pooling
	// thick on roofs and floors, gathering where metal burns.
	float wisp = smoothstep(0.45, 0.85, n);
	float density = thickness * (0.04 + 0.5 * wisp) * (0.3 + 1.6 * pool) + gather * 0.18;
	density += thickness * near * 0.25;
	for (int i = 0; i < repeller_count; i++) {
		float radius = repellers[i].z;
		float r = distance(world, repellers[i].xy);
		density *= mix(1.0, smoothstep(radius * 0.5, radius, r), repellers[i].w);
	}
	density *= open_air;
	density *= 1.0 - thin * 0.75;
	vec3 col = mix(mist_color.rgb, steel_color.rgb, blue_tint);
	float alpha = clamp(density, 0.0, 0.5);
	// The night closes in softly beyond Vin's sight: a wide, gentle falloff
	// rather than a disc.
	float outside = smoothstep(vision_radius * 0.4, vision_radius * 1.6, distance(world, vision_center));
	// Beyond her sight the night darkens (toward black, never toward grey).
	col = mix(col, vec3(0.01, 0.012, 0.02), outside);
	alpha = mix(alpha, max(alpha, 0.45), outside);
	COLOR = vec4(col, alpha);
}
