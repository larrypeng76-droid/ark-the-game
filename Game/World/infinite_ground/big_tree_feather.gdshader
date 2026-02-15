shader_type canvas_item;

uniform float feather_px : hint_range(0.0, 64.0) = 2.0;
uniform float alpha_multiplier : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Feather alpha near sprite borders in texture-space pixels.
	vec2 feather_uv = TEXTURE_PIXEL_SIZE * max(feather_px, 0.0);
	vec2 edge_dist = min(UV, vec2(1.0) - UV);
	float fade_x = smoothstep(0.0, max(feather_uv.x, 1e-6), edge_dist.x);
	float fade_y = smoothstep(0.0, max(feather_uv.y, 1e-6), edge_dist.y);
	float edge_fade = min(fade_x, fade_y);

	tex.a *= edge_fade * alpha_multiplier;
	COLOR = tex;
}
