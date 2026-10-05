extends SceneTree
var checks := 0
var failures := 0
var viewport: SubViewport
func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func capture() -> Image:
	for frame in 2: await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()

func run_tests() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(900, 640)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	viewport.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("sunflower", Vector2i(3, 2))
	var plant: Dictionary = game.plants[-1]
	var zombie: Dictionary = game.spawn_zombie(2, false, game.cell_center(plant.cell).x + 22)
	game.simulate(0.2)
	for node in game.get_children():
		if node is CanvasLayer: node.visible = false
		elif node is CanvasItem and node != plant.art and node != zombie.art: node.hide()
	var hat: Sprite2D = plant.rank_hat
	for rank in 3:
		hat.set_rank(rank + 1)
		hat.show()
		plant.art.show()
		zombie.art.show()
		var actual := await capture()
		if rank == 2: actual.save_png("res://build/hat-occlusion.png")
		hat.hide()
		var without_hat := await capture()
		plant.art.hide()
		var zombie_only := await capture()
		zombie.art.hide()
		var isolated := hat.duplicate()
		viewport.add_child(isolated)
		isolated.global_transform = hat.global_transform
		isolated.z_index = 0
		isolated.show()
		var hat_only := await capture()
		isolated.free()
		var overlapping := 0
		var mismatches := 0
		for y in actual.get_height():
			for x in actual.get_width():
				if hat_only.get_pixel(x, y).a > 0.99 and zombie_only.get_pixel(x, y).a > 0.9999:
					overlapping += 1
					var a := actual.get_pixel(x, y)
					var b := without_hat.get_pixel(x, y)
					# Allow one 8-bit blend rounding step at composite sprite edges.
					if maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b))) > 1.01 / 255.0: mismatches += 1
		check(overlapping > 5, "rank %d hat actually overlaps opaque biting-zombie pixels (%d)" % [rank + 1, overlapping])
		check(mismatches == 0, "rank %d zombie fully occludes the cap in actual GPU output (%d incorrect pixels)" % [rank + 1, mismatches])
	viewport.free()
	await process_frame
	print("Hat occlusion/GPU checks: %d; failures: %d" % [checks, failures])
	quit(failures)
