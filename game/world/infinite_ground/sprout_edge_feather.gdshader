shader_type canvas_item;

uniform float feather_px : hint_range(0.0, 8.0, 0.1) = 1.5;
uniform float alpha_softness : hint_range(0.001, 1.0, 0.001) = 0.22;
uniform float alpha_multiplier : hint_range(0.0, 1.0, 0.01) = 0.92;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	tex_size = max(tex_size, vec2(1.0));

	// Remove dark fringe from filtered transparent pixels by converting
	// sampled premultiplied-like color back to straight alpha color.
	vec3 base_rgb = tex.rgb;
	if (tex.a > 0.0001) {
		base_rgb = tex.rgb / tex.a;
	}

	vec2 feather_uv = vec2(feather_px) / tex_size;
	float edge_u = min(UV.x, 1.0 - UV.x);
	float edge_v = min(UV.y, 1.0 - UV.y);
	float edge_mask_u = smoothstep(0.0, feather_uv.x, edge_u);
	float edge_mask_v = smoothstep(0.0, feather_uv.y, edge_v);
	float edge_mask = min(edge_mask_u, edge_mask_v);

	float alpha = smoothstep(0.0, max(alpha_softness, 0.001), tex.a);
	alpha *= edge_mask * alpha_multiplier;

	COLOR = vec4(base_rgb, alpha);
}
