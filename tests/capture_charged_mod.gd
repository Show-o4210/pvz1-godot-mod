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
	game.sun_count = 1500
	var pea := add_plant(game, "peashooter", Vector2i(2, 2), 2)
	add_plant(game, "peashooter", Vector2i(4, 2))
	var flower := add_plant(game, "sunflower", Vector2i(0, 1), 3)
	add_plant(game, "sunflower", Vector2i(1, 1))
	add_plant(game, "sunflower", Vector2i(0, 2))
	game.spawn_zombie(2, true, 750)
	game.control.select(pea, game.plants)
	game.request_controlled_action()
	DirAccess.make_dir_recursive_absolute("res://build/charged-mod-frames")
	for tick in 600:
		if tick == 150:
			game.control.select(flower, game.plants)
			game.request_controlled_action()
		if tick == 299 and flower.auto_until <= game.elapsed:
			push_error("Preview sunflower action was interrupted")
			quit(1)
			return
		if tick == 300: game.release_controlled_action()
		if tick == 330:
			for sun in game.suns.duplicate(): game.collect_sun(sun)
		if tick == 360:
			game.control.select(pea, game.plants)
			game.request_controlled_action()
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
		if tick % 3 == 0:
			# Background/minimized windows may skip normal frame_post_draw.
			RenderingServer.force_draw()
			var frame := root.get_texture().get_image()
			frame.resize(800, 600, Image.INTERPOLATE_LANCZOS)
			frame.save_png("res://build/charged-mod-frames/%03d.png" % (tick / 3))
			if tick == 30: frame.save_png("res://build/mod-v0.2.png")
	print("Local charged Mod preview captured: 10 seconds.")
	quit()
