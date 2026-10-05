extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("sunflower", Vector2i(0, 1))
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", Vector2i(0, 3))
	game.try_plant("peashooter", Vector2i(2, 2))
	game.try_plant("wallnut", Vector2i(5, 2))
	game.spawn_zombie(2, false, 655)
	game.spawn_zombie(3, true, 735)
	game.fire_pea(2, 450)
	game.spawn_sun(Vector2(310, 250))
	game.sun_count = 125
	game._update_hud()
	for i in 15:
		game._update_presentation(1.0 / 60.0)
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build")
	var picture := root.get_texture().get_image()
	var code := picture.save_png("res://build/preview.png")
	print("Preview captured: ", code)
	quit(code)
