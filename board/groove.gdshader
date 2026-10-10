shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, specular_disabled;
// A pill-shaped groove tinted a seat colour, drawn on a flat plane.
// Everything outside the stadium (a capsule seen from above) is discarded.

uniform vec4 color : source_color = vec4(1.0);
// Half the plane's size in local units: x across, z along the groove.
uniform vec2 half_size = vec2(0.525, 2.6213);
uniform float fill_alpha : hint_range(0.0, 1.0) = 0.22;
uniform float border_alpha : hint_range(0.0, 1.0) = 0.55;
uniform float border_width = 0.05;

varying vec2 local_xz;


void vertex() {
	local_xz = VERTEX.xz;
}


// Signed distance to a stadium centred on the origin, lying along z.
float stadium_distance(vec2 p) {
	float radius = half_size.x;
	float half_segment = max(half_size.y - radius, 0.0);
	p.y = max(abs(p.y) - half_segment, 0.0);
	return length(p) - radius;
}


void fragment() {
	float d = stadium_distance(local_xz);
	float aa = fwidth(d);
	float inside = 1.0 - smoothstep(-aa, aa, d);
	if (inside <= 0.0) {
		discard;
	}
	float border = smoothstep(-border_width - aa, -border_width + aa, d);
	ALBEDO = color.rgb;
	ROUGHNESS = 1.0;
	ALPHA = mix(fill_alpha, border_alpha, border) * inside;
}
