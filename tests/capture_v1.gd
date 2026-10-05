extends SceneTree
## Staged visual verification, never used by the playable main scene.

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
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(1, 3))
	game.try_plant("wallnut", Vector2i(4, 1))
	var nut: Dictionary = game.plants[-1]
	nut.hp = 2690
	game.spawn_zombie(1, false, game.cell_center(nut.cell).x + 25)
	var victim: Dictionary = game.spawn_zombie(2, false, 495)
	game.damage_zombie(victim, 60)
	var cone: Dictionary = game.spawn_zombie(3, true, 650)
	game.damage_zombie(cone, 190)
	game.spawn_sun(Vector2(290, 220))
	game.sun_count = 125
	DirAccess.make_dir_recursive_absolute("res://build/v1-frames")
	for tick in 480:
		if tick == 150: game.spawn_zombie(4, false, 55)
		if tick == 210:
			nut.hp = 1200
			nut.art.get_meta("view").set_health(nut.hp, 4000)
		game.simulate(1.0 / 60.0)
		game._update_hud()
		await process_frame
		if tick % 3 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/v1-frames/%03d.png" % (tick / 3))
		if tick == 225:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/v1-damage.png")
	game.toggle_pause()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/v1-menu.png")
	print("V1 animation frames, damage preview and menu captured.")
	quit()
