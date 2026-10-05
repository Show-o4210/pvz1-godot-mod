extends SceneTree
## One charged action at a time, normal economy/cards, original three waves.
func _initialize() -> void:
	call_deferred("playthrough")

func at(game: Node, cell: Vector2i) -> Dictionary:
	for plant in game.plants:
		if plant.cell == cell: return plant
	return {}

func playthrough() -> void:
	seed(1051)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.silent = true
	var actions := 0
	for tick in 60 * 360:
		if not game.result.is_empty(): break
		if not game.control.fire_held:
			for sun in game.suns.duplicate(): game.collect_sun(sun)
			if at(game, Vector2i(0, 2)).is_empty(): game.try_plant("sunflower", Vector2i(0, 2))
			if at(game, Vector2i(0, 1)).is_empty() and game.elapsed < 20: game.try_plant("sunflower", Vector2i(0, 1))
			var farm := at(game, Vector2i(0, 2))
			if not farm.is_empty() and farm.rank < 2 and game.elapsed < 20: game.try_plant("sunflower", farm.cell)
			for row in [2, 1, 3, 0, 4]:
				if at(game, Vector2i(1, row)).is_empty(): game.try_plant("peashooter", Vector2i(1, row))
			var nearest: Dictionary = {}
			for zombie in game.zombies:
				if zombie.art.get_meta("view").head_lost: continue
				if nearest.is_empty() or zombie.x < nearest.x: nearest = zombie
			var candidate: Dictionary = {}
			if not nearest.is_empty():
				var shooter := at(game, Vector2i(1, nearest.row))
				if not shooter.is_empty():
					if game.sun_count >= 150 and shooter.rank < 3: game.try_plant("peashooter", shooter.cell)
					if shooter.windup < 0 and shooter.attack <= 0: candidate = shooter
			if not farm.is_empty() and farm.auto_until <= game.elapsed and (nearest.is_empty() or nearest.x > 650 or candidate.is_empty()):
				candidate = farm
			if not candidate.is_empty():
				game.control.select(candidate, game.plants)
				game.request_controlled_action()
		var active: Dictionary = game.control.selected_plant
		var before: float = active.get("charge", 0.0)
		game.simulate(1.0 / 60.0)
		if not active.is_empty() and before > 0 and active.charge == 0:
			actions += 1
			game.release_controlled_action()
		if tick % 60 == 0: await process_frame
	var passed: bool = game.result == "胜利！" and game.defeated == 15 and game.control.enabled and actions > 0
	print("Charged full level: result=%s, time=%.1fs, defeated=%d, completed_holds=%d, manual=%s" % [game.result, game.elapsed, game.defeated, actions, game.control.enabled])
	game.free()
	await process_frame
	quit(0 if passed else 1)
