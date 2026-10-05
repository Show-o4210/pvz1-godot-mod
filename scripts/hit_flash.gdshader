shader_type canvas_item;
uniform float flash : hint_range(0.0, 0.4) = 0.0;
void fragment() {
	// Godot's fragment COLOR already includes TEXTURE, modulate and alpha.
	// Sampling and multiplying again squares every color and darkens the art.
	vec4 tex = COLOR;
	COLOR = vec4(min(tex.rgb + vec3(flash), vec3(1.0)), tex.a);
}
