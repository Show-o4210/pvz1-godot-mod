extends SceneTree
var game: Node
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, description: String) -> void:
	checks += 1
	if value: print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func fresh() -> void:
	if is_instance_valid(game): game.free()
	game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 5000

func plant(kind: String, cell: Vector2i, rank := 1) -> Dictionary:
	game.cooldowns[kind] = 0
	game.try_plant(kind, cell)
	var item: Dictionary = game.plants[-1]
	for upgrade in rank - 1:
		game.cooldowns[kind] = 0
		game.try_plant(kind, cell)
	return item

func step(seconds: float) -> void:
	for tick in roundi(seconds * 60): game.simulate(1.0 / 60.0)

func hold(item: Dictionary, seconds: float) -> void:
	game.control.select(item, game.plants)
	game.request_controlled_action()
	step(seconds)
	game.release_controlled_action()

func harvest(cell: Vector2i) -> int:
	var value := 0
	for sun in game.suns.duplicate():
		if sun.get("source_cell", Vector2i(-1, -1)) == cell: value += sun.value
		game.collect_sun(sun)
	return value

func run_tests() -> void:
	fresh()
	var a := plant("sunflower", Vector2i(2, 2), 2)
	var b := plant("sunflower", Vector2i(3, 2), 3)
	var c := plant("sunflower", Vector2i(4, 2))
	var diagonal := plant("sunflower", Vector2i(1, 1))
	step(30)
	check(a.sun_state == "stop" and game.suns.is_empty() and a.sun_ready == 8, "Stop freezes production even over a long idle period")
	hold(a, 2.4)
	check(game.suns.is_empty() and a.sun_state == "work", "full activation starts Work with no immediate payout")
	check(b.sun_state == "weak_work" and diagonal.sun_state == "weak_work", "only immediate and diagonal neighbors enter Weak Work")
	check(c.sun_state == "stop" and c.auto_until == 0, "activation never recursively spreads to a second ring")
	check(absf(a.auto_until - game.elapsed - 20) < 0.02 and b.auto_until == a.auto_until, "neighbors inherit the activating rank's bounded duration")
	step(7.9)
	check(game.suns.is_empty(), "no sunflower payout before the eight-second production interval")
	step(0.15)
	check(game.suns.size() == 3 and game.suns[0].value == 30 and game.suns[1].value == 26, "production uses each plant's own rank and linked 75 percent efficiency")
	var pending: float = a.sun_ready
	var count: int = game.suns.size()
	for duplicate in 8: game._activate_sun_network(a)
	check(game.suns.size() == count and a.sun_ready == pending and b.sun_ready == pending, "overlapping activations never reset the interval or mint duplicate sun")
	check(a.auto_until <= game.elapsed + 20.000001, "repeated activation refreshes without accumulating durations")
	var deadline: float = a.auto_until
	step(8)
	check(a.auto_until == deadline and harvest(a.cell) == 60, "automatic production does not extend its own work duration")
	fresh()
	a = plant("sunflower", Vector2i(2, 2))
	hold(a, 2.4)
	step(3)
	pending = a.sun_ready
	hold(a, 2.4)
	check(absf(a.sun_ready - (pending - 2.4)) < 0.02, "manual refresh preserves the running production cycle")
	check(game.suns.is_empty(), "refreshing Work grants no immediate production")
	step(2.65)
	check(game.suns.size() == 1, "refreshed Work still produces at the original cycle boundary")
	step(9.4)
	check(a.sun_state == "stop", "expired Work automatically becomes Stop")
	pending = a.sun_ready
	step(20)
	check(absf(a.sun_ready - pending) < 0.000001, "Stop preserves partially completed production")
	hold(a, 2.4)
	check(game.suns.is_empty() and absf(a.sun_ready - pending) < 0.000001, "resuming after idle does not pay a backlog or reset progress")
	step(pending + 0.02)
	check(game.suns.size() == 1, "resumed Work finishes only the remaining portion of the cycle")
	fresh()
	a = plant("sunflower", Vector2i(2, 2), 3)
	b = plant("sunflower", Vector2i(3, 2))
	hold(a, 2.4)
	step(3)
	pending = b.sun_ready
	hold(b, 2.4)
	check(b.sun_state == "work" and absf(b.sun_ready - (pending - 2.4)) < 0.02, "Weak Work promoted to Work retains production progress")
	check(b.linked_until > b.full_until, "full and linked work keep separate expiration deadlines")
	step(2.65)
	check(harvest(b.cell) == 25, "production during direct Work gets full own-rank value")
	step(9.4)
	check(b.sun_state == "weak_work" and b.auto_efficiency == 0.75, "expiration of shorter Work restores the longer Weak Work")
	step(6.1)
	check(harvest(b.cell) >= 18, "production after Work expiration correctly receives the linked penalty")
	fresh()
	a = plant("sunflower", Vector2i(2, 2), 3)
	b = plant("sunflower", Vector2i(3, 2), 3)
	var total := 0
	for cycle in 4:
		game._activate_sun_network(a)
		step(8)
		total += harvest(b.cell)
	check(total == 105 and absf(b.sun_fraction) < 0.000001, "four linked rank-three cycles sum to exactly 105 sun, including fractional carry")
	game.toggle_pause()
	pending = a.sun_ready
	deadline = a.auto_until - game.elapsed
	step(2)
	check(a.sun_ready == pending and absf(a.auto_until - game.elapsed - deadline) < 0.000001, "pause freezes both work duration and production progress")
	game.toggle_pause()
	fresh()
	a = plant("sunflower", Vector2i(2, 2))
	game._activate_sun_network(a)
	game.elapsed += 15
	game._update_plants(15)
	check(game.suns.size() == 1 and a.sun_state == "stop" and absf(a.sun_ready - 4) < 0.0001, "large step advances only the twelve working seconds, not its inactive tail")
	game._activate_sun_network(a)
	game.elapsed += 12
	game._update_plants(12)
	check(game.suns.size() == 3 and absf(a.sun_ready - 8) < 0.0001, "production at an exact expiry boundary happens once and preserves cadence")
	for rank in 3:
		fresh()
		a = plant("sunflower", Vector2i(2, 2), rank + 1)
		game._activate_sun_network(a)
		step(8)
		check(game.suns.size() == 1 and game.suns[0].value == [25, 30, 35][rank], "rank %d has its own modest sunflower yield" % (rank + 1))
	for rank in 3:
		fresh()
		a = plant("peashooter", Vector2i(1, 2), rank + 1)
		b = plant("peashooter", Vector2i(3, 2))
		c = plant("peashooter", Vector2i(1, 3))
		var rounds: int = [3, 2, 1][rank]
		for cycle in rounds:
			hold(a, game.Rules.charge_time(a))
			check((b.windup >= 0) == (cycle == rounds - 1), "rank %d only links on completed round %d/%d" % [rank + 1, cycle + 1, rounds])
			if cycle < rounds - 1: step(0.37)
		check(game.row_energy[2] == 0 and c.windup < 0, "rank %d volley clears its full row energy and never crosses rows" % (rank + 1))
		step(0.37)
		check(game.projectiles[-1].damage == 20 and game.projectiles[-2].damage == [20, 24, 28][rank], "rank %d linked shots keep both plants' own damage without duplicating primary" % (rank + 1))
	fresh()
	a = plant("peashooter", Vector2i(1, 2))
	b = plant("peashooter", Vector2i(3, 2), 2)
	c = plant("peashooter", Vector2i(5, 2), 3)
	hold(a, 0.95)
	step(0.37)
	check(game.row_energy[2] == 2, "rank-one full charge adds one third row energy")
	hold(b, 0.8)
	step(0.37)
	check(game.row_energy[2] == 5, "switching to rank two adds one half without resetting the shared energy")
	hold(a, 0.95)
	check(game.row_energy[2] == 1 and b.windup >= 0 and c.windup >= 0, "mixed ranks trigger one row volley and retain only fractional overflow")
	step(0.37)
	hold(c, 0.65)
	check(game.row_energy[2] == 1 and a.windup >= 0 and b.windup >= 0, "rank-three commander triggers one volley without discarding fractional overflow")
	step(0.37)
	game.control.select(a, game.plants)
	for click in 10:
		game.request_controlled_action()
		step(0.1)
		game.release_controlled_action()
	check(game.row_energy[2] == 1, "incomplete holds and linked shots contribute no row energy")
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", a.cell)
	check(game.row_energy[2] == 1, "upgrading does not retroactively recalculate shared row energy")
	game._remove_entity(game.plants, b)
	check(game.row_energy[2] == 1, "removing one member preserves energy while the row can still link")
	game._remove_entity(game.plants, c)
	check(game.row_energy[2] == 0, "a single surviving shooter clears unusable row energy")
	game._remove_entity(game.plants, a)
	check(game.control.selected_plant.is_empty(), "empty row and removed selected plant leave no stale input")
	game.free()
	await process_frame
	print("Plant network checks: %d; failures: %d" % [checks, failures])
	quit(failures)
