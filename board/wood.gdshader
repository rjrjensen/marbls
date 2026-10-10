shader_type spatial;
// Warm wood for the board top: a diagonal light-to-dark gradient (light at
// the far left, dark at the near right, like the prototype) with faint grain
// lines running toward the viewer.

uniform vec3 light_wood : source_color = vec3(0.839, 0.663, 0.416);
uniform vec3 mid_wood : source_color = vec3(0.733, 0.537, 0.298);
uniform vec3 dark_wood : source_color = vec3(0.663, 0.486, 0.259);
// Half the board's width (x) and depth (z), set by BoardView.
uniform vec2 half_size = vec2(8.0, 8.0);
uniform float grain_spacing = 0.52;
uniform float grain_strength = 0.09;

varying vec3 board_position;

void vertex() {
	board_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = board_position.xz / half_size;
	float t = clamp((p.x + p.y) * 0.25 + 0.5, 0.0, 1.0);
	vec3 wood = t < 0.55 ? mix(light_wood, mid_wood, t / 0.55) : mix(mid_wood, dark_wood, (t - 0.55) / 0.45);
	// Grain: thin lines that wander a little, so they don't look ruled.
	float lane = floor(board_position.x / grain_spacing);
	float x = board_position.x + 0.12 * sin(board_position.z * 0.8 + lane * 1.7);
	float line = 1.0 - smoothstep(0.0, 0.06, abs(fract(x / grain_spacing) - 0.5) * grain_spacing);
	wood *= 1.0 - grain_strength * line;
	ALBEDO = wood;
	ROUGHNESS = 0.55;
}
