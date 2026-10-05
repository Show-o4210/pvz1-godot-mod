extends SceneTree
func _initialize() -> void:
	call_deferred("capture")

func add_plant(game: Node, kind: String, cell: Vector2i, rank := 1) -> Dictionary:
	game.cooldowns[kind] = 0
	game.try_plant(kind, cell)
	var plant: Dictionary = game.plants[-1]
	for upgrade in rank - 1:
		game.cooldowns[kind] = 0
		game.try_plant(kind, cell)
	return plant

func capture() -> void:
	seed(1051)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.silent = true
	game.sun_count = 3000 # Visual fixture only.
	# Compress announcement timing for the preview; normal schedule is untouched.
	game.schedule.assign([
		{"time": 4.0, "row": 0, "cone": false, "wave": 1},
		{"time": 8.0, "row": 3, "cone": true, "wave": 2},
		{"time": 15.0, "row": 2, "cone": false, "wave": 3}])
	var pea := add_plant(game, "peashooter", Vector2i(3, 0), 3)
	add_plant(game, "peashooter", Vector2i(1, 0), 2)
	var flower := add_plant(game, "sunflower", Vector2i(0, 1), 3)
	add_plant(game, "sunflower", Vector2i(1, 1), 2)
	var disposable := add_plant(game, "sunflower", Vector2i(4, 0))
	game.control.select(flower, game.plants)
	game.request_controlled_action()
	game.silent = false
	for tick in 1380:
		if tick == 360: game.release_controlled_action()
		if tick == 480: game.select_seed("peashooter")
		if tick == 510: game.cancel_selection()
		if tick == 540: game.select_seed("shovel")
		if tick == 570: game.cancel_selection()
		if tick == 600:
			game.select_seed("shovel")
			game.handle_click(game.cell_center(disposable.cell))
		if tick == 660:
			var snack := add_plant(game, "sunflower", Vector2i(6, 3))
			snack.hp = 5
			game.spawn_zombie(3, false, game.cell_center(snack.cell).x + 30)
		if tick == 720:
			game.spawn_zombie(0, false, game.cell_center(pea.cell).x + 30)
			pea.hp = 5000 # Keep the overlap visible; preview fixture only.
			game.control.select(pea, game.plants)
			game.request_controlled_action()
		if tick == 870:
			for sun in game.suns.duplicate(): game.collect_sun(sun)
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
		if tick in [449, 809, 1139]:
			RenderingServer.force_draw()
			var frame := root.get_texture().get_image()
			frame.resize(800, 690, Image.INTERPOLATE_LANCZOS)
			frame.save_png("res://build/mod-v0.4-%d.png" % tick)
			if tick == 809: frame.save_png("res://build/mod-v0.4.png")
	if game.level_cues.fired.size() != 4 or flower.sun_state != "work":
		push_error("Preview missed announcements or doubled Work duration.")
		quit(1)
		return
	print("Feedback Mod preview: 23 seconds, Ready/first/huge/final cues, toolbar, cap occlusion, tool/drop/gulp audio and autonomous supply.")
	game.free()
	await process_frame
	quit()
