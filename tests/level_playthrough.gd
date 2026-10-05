extends SceneTree

func _initialize() -> void:
	call_deferred("playthrough")

func occupied(game: Node, cell: Vector2i) -> bool:
	for plant in game.plants:
		if plant.cell == cell:
			return true
	return false

func playthrough() -> void:
	seed(1051)
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.silent = true
	var dt := 1.0 / 60.0
	for tick in 60 * 300:
		if not game.result.is_empty():
			break
		if tick % 15 == 0:
			for sun in game.suns.duplicate():
				game.collect_sun(sun)
			# All planting uses normal cost, occupancy, and cooldown checks.
			for row in [2, 1, 3, 0, 4]:
				if not occupied(game, Vector2i(1, row)):
					game.try_plant("peashooter", Vector2i(1, row))
			for row in [2, 1, 3]:
				if not occupied(game, Vector2i(0, row)):
					game.try_plant("sunflower", Vector2i(0, row))
			for row in [2, 1, 3, 0, 4]:
				if not occupied(game, Vector2i(2, row)):
					game.try_plant("peashooter", Vector2i(2, row))
		game.simulate(dt)
		if tick % 60 == 0:
			await process_frame
	print("Full level: result=%s, time=%.1fs, spawned=%d, defeated=%d, sun=%d" % [game.result, game.elapsed, game.spawn_index, game.defeated, game.sun_count])
	var passed: bool = game.result == "胜利！" and game.defeated == 15
	game.free()
	await process_frame
	quit(0 if passed else 1)
