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
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 3000 # Visual fixture only; normal start still has 50 sun.
	var pea := add_plant(game, "peashooter", Vector2i(3, 2), 2)
	add_plant(game, "peashooter", Vector2i(1, 2), 3)
	add_plant(game, "peashooter", Vector2i(5, 2))
	var flower := add_plant(game, "sunflower", Vector2i(0, 1), 3)
	add_plant(game, "sunflower", Vector2i(1, 1))
	add_plant(game, "sunflower", Vector2i(0, 2), 2)
	add_plant(game, "sunflower", Vector2i(3, 1), 2)
	game.spawn_zombie(2, true, 790)
	game.control.select(pea, game.plants)
	game.request_controlled_action()
	DirAccess.make_dir_recursive_absolute("res://build/work-mod-frames")
	for tick in 1440:
		if tick == 120:
			game.control.select(flower, game.plants)
			game.request_controlled_action()
		if tick == 300:
			game.release_controlled_action()
			if flower.sun_state != "work" or not game.suns.is_empty():
				push_error("Preview activation failed or gave instant sun")
				quit(1)
				return
		if tick in [780, 1290]:
			if game.suns.size() != 3:
				push_error("Preview did not produce the expected autonomous supply")
				quit(1)
				return
			for sun in game.suns.duplicate(): game.collect_sun(sun)
		if tick == 840:
			game.control.select(pea, game.plants)
			game.request_controlled_action()
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
		if tick % 3 == 0:
			RenderingServer.force_draw()
			var frame := root.get_texture().get_image()
			frame.resize(800, 600, Image.INTERPOLATE_LANCZOS)
			frame.save_png("res://build/work-mod-frames/%03d.png" % (tick / 3))
			if tick == 430 - 1: frame.save_png("res://build/mod-v0.3.png")
	print("Local Work Mod preview captured: 24 seconds, two automatic supply cycles.")
	quit()
