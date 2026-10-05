extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	seed(1051)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("peashooter", Vector2i(1, 2))
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(1, 3))
	game.try_plant("sunflower", Vector2i(0, 1))
	game.try_plant("wallnut", Vector2i(4, 2))
	game.spawn_zombie(2, true, 610)
	game.spawn_zombie(3, false, 690)
	game.sun_count = 125
	game.handle_click(game.cell_center(Vector2i(1, 2)))
	game.request_controlled_action()
	for tick in 35:
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	root.get_texture().get_image().save_png("res://build/mod-manual.png")
	print("Manual prototype captured with selected shooter, status and moving pea.")
	quit()
