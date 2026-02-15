shader_type canvas_item;

uniform vec2 clear_center = vec2(0.0, 0.0);
uniform float clear_radius = 60.0;
uniform float edge_fade = 14.0;
uniform float darkness_alpha : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 diff = FRAGCOORD.xy - clear_center;
	float dist = length(diff);
	float soft = max(edge_fade, 0.0001);
	float ring = smoothstep(clear_radius - soft, clear_radius + soft, dist);
	COLOR = vec4(0.0, 0.0, 0.0, darkness_alpha * ring);
}
