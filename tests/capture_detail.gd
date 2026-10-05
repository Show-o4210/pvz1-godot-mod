extends SceneTree
## Demonstrates shared plant sway, zombie gait, plant contact and resuming gait.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	seed(1051)
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("sunflower", Vector2i(0, 1))
	game.try_plant("peashooter", Vector2i(1, 2))
	game.try_plant("wallnut", Vector2i(4, 3))
	var nut: Dictionary = game.plants[-1]
	game.spawn_zombie(2, false, 665)
	game.spawn_zombie(3, true, game.cell_center(nut.cell).x + 50)
	game.spawn_zombie(0, false, 720)
	game.sun_count = 125
	DirAccess.make_dir_recursive_absolute("res://build/detail-frames")
	for tick in 480:
		if tick == 240: game._remove_entity(game.plants, nut)
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
		if tick % 3 == 0:
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			if tick == 90: frame.save_png("res://build/v1-detail.png")
			frame.resize(800, 600, Image.INTERPOLATE_LANCZOS)
			frame.save_png("res://build/detail-frames/%03d.png" % (tick / 3))
	print("Detail preview rendered: shared sway, jaw, walking/contact/resume.")
	quit()
