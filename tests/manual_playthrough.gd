extends SceneTree
## Explicit command bot; never enables automatic shooting or bypasses economy.

func _initialize() -> void:
	call_deferred("playthrough")

func occupied(game: Node, cell: Vector2i) -> bool:
	for plant in game.plants:
		if plant.cell == cell: return true
	return false

func playthrough() -> void:
	seed(1051)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.silent = true
	var commands := 0
	for tick in 60 * 300:
		if not game.result.is_empty(): break
		if tick % 15 == 0:
			for sun in game.suns.duplicate(): game.collect_sun(sun)
			for row in [2, 1, 3, 0, 4]:
				if not occupied(game, Vector2i(1, row)): game.try_plant("peashooter", Vector2i(1, row))
			for row in [2, 1, 3]:
				if not occupied(game, Vector2i(0, row)): game.try_plant("sunflower", Vector2i(0, row))
			for row in [2, 1, 3, 0, 4]:
				if not occupied(game, Vector2i(2, row)): game.try_plant("peashooter", Vector2i(2, row))
		# At most one explicit attack command per simulation tick. The plant's
		# own cooldown, windup and real projectile collisions still govern combat.
		for plant in game.plants:
			if not game.control.can_control(plant) or plant.attack > 0 or plant.windup >= 0: continue
			var enemy_ahead := false
			for zombie in game.zombies:
				if zombie.row == plant.cell.y and zombie.x > game.cell_center(plant.cell).x - 15:
					enemy_ahead = true
					break
			if enemy_ahead:
				game.control.select(plant, game.plants)
				if game.request_controlled_action():
					commands += 1
					break
		game.simulate(1.0 / 60.0)
		if tick % 60 == 0: await process_frame
	var passed: bool = game.result == "胜利！" and game.defeated == 15 and game.control.enabled and commands > 0
	print("Manual full level: result=%s, time=%.1fs, defeated=%d, commands=%d, manual=%s" % [game.result, game.elapsed, game.defeated, commands, game.control.enabled])
	game.free()
	await process_frame
	quit(0 if passed else 1)
