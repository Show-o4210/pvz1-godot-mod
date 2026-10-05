extends SceneTree
## Actual GPU comparison against Godot's default Sprite2D rendering, including
## texture alpha, tint and parent opacity. Cannot be validated headlessly.
var failures := 0

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(128, 128)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var texture_image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			texture_image.set_pixel(x, y, Color(0.2 + x * 0.04, 0.3 + y * 0.03, 0.55, 0.15 + x * 0.05))
	var texture := ImageTexture.create_from_image(texture_image)
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/hit_flash.gdshader")
	var cases := [Color.WHITE, Color(0.7, 0.9, 0.5, 1), Color(1, 1, 1, 0.45), Color(0.8, 0.7, 0.9, 0.5)]
	for i in cases.size():
		for column in 2:
			var parent := Node2D.new()
			parent.position = Vector2(column * 64 + 8, i * 28 + 8)
			parent.modulate = cases[i]
			viewport.add_child(parent)
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.self_modulate = Color(0.9, 0.95, 0.85, 0.8)
			if column == 1: sprite.material = material
			parent.add_child(sprite)
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	for i in cases.size():
		var maximum_error := 0.0
		for y in 16:
			for x in 16:
				var reference := image.get_pixel(x + 8, y + i * 28 + 8)
				var result := image.get_pixel(x + 72, y + i * 28 + 8)
				for channel in 4: maximum_error = maxf(maximum_error, absf(reference[channel] - result[channel]))
		if maximum_error <= 1.0 / 255:
			print("PASS: neutral shader matches original RGBA; tint case ", i, "; max error ", maximum_error)
		else:
			failures += 1
			push_error("Color mismatch in case %d: %f" % [i, maximum_error])
	DirAccess.make_dir_recursive_absolute("res://build")
	image.save_png("res://build/color-neutral-check.png")
	material.set_shader_parameter("flash", 0.3)
	for i in 2: await process_frame
	await RenderingServer.frame_post_draw
	var hit_image := viewport.get_texture().get_image()
	var original := image.get_pixel(80, 16)
	var hit := hit_image.get_pixel(80, 16)
	if hit.r > original.r and hit.g > original.g and hit.b > original.b and absf(hit.a - original.a) < 1.0 / 255:
		print("PASS: hit flash brightens RGB and preserves alpha")
	else:
		failures += 1
		push_error("Hit flash must preserve alpha while brightening")
	viewport.queue_free()
	await process_frame
	print("GPU color checks: 5; failures: ", failures)
	quit(failures)
