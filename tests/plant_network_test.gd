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
	hold(a, 2.4)
	check(game.suns.size() == 3, "sun hold activates only primary and its immediate neighbors")
	check(game.sunflower_neighbors(a).has(diagonal), "diagonal cell participates in the eight-cell ring")
	check(c.sun_ready == 0 and c.auto_until == 0, "neighbors do not propagate to a second ring")
	check(absf(a.auto_until - game.elapsed - 6) < 0.02, "second rank rewards a six-second automatic window")
	check(b.auto_until == a.auto_until and b.auto_efficiency == 0.75, "higher-rank neighbor inherits primary window rather than its own rank duration")
	check(game.suns[0].value == 25 and game.suns[1].value == 18, "primary produces full value and neighbor starts the 75 percent sequence")
	var count: int = game.suns.size()
	game._activate_sun_network(a)
	check(game.suns.size() == count, "duplicate activation cannot bypass the shared production interval")
	var cutoff: float = a.auto_until
	step(4.05)
	check(game.suns.size() == 6 and c.sun_ready == 0, "automatic window produces without recursive expansion")
	check(a.auto_until == cutoff, "automatic production does not renew its own window")
	step(4)
	check(game.suns.size() == 6 and a.auto_until < game.elapsed, "expired window stops production")
	fresh()
	a = plant("sunflower", Vector2i(2, 2))
	b = plant("sunflower", Vector2i(3, 2))
	var total := 0
	for round_index in 4:
		hold(a, 2.4)
		total += harvest(b.cell)
		step(4.05)
	check(total == 75 and absf(b.sun_fraction) < 0.000001, "four linked rounds produce exactly 75 sun with fractional carry")
	fresh()
	a = plant("sunflower", Vector2i(2, 2), 3)
	b = plant("sunflower", Vector2i(3, 2))
	var other := plant("sunflower", Vector2i(2, 3), 2)
	hold(a, 2.4)
	var before: int = game.suns.size()
	hold(other, 2.4)
	check(game.suns.size() == before, "overlapping charged neighbors cannot receive double production within four seconds")
	check(b.auto_until <= game.elapsed + 12.000001, "overlapping windows remain bounded instead of adding durations")
	game.control.select(a, game.plants)
	game.request_controlled_action()
	step(8)
	game.release_controlled_action()
	check(a.auto_until > game.elapsed and a.auto_until <= game.elapsed + 12.000001, "sustained manual work refreshes without unbounded accumulated time")
	game.toggle_pause()
	cutoff = a.auto_until - game.elapsed
	step(2)
	check(absf(a.auto_until - game.elapsed - cutoff) < 0.000001, "pause preserves the remaining reward window")
	game.toggle_pause()
	fresh()
	a = plant("sunflower", Vector2i(2, 2), 2)
	b = plant("sunflower", Vector2i(3, 2), 3)
	hold(a, 2.4)
	hold(b, 4.05)
	check(a.linked_until > a.full_until, "neighbor's longer window retains its own efficiency deadline")
	step(4.05)
	check(a.full_until < game.elapsed and a.auto_efficiency == 0.75, "expired full-efficiency reward cannot upgrade a longer neighbor window")
	fresh()
	a = plant("peashooter", Vector2i(1, 2))
	b = plant("peashooter", Vector2i(3, 2), 3)
	c = plant("peashooter", Vector2i(1, 3))
	hold(a, 0.95)
	step(0.37)
	check(game.projectiles.size() == 1 and game.row_rounds[2] == 1, "first completed charge shoots primary and stores one row round")
	check(b.windup < 0 and c.windup < 0, "neighbors wait for the full-round threshold")
	hold(a, 0.95)
	step(0.37)
	check(game.projectiles.size() == 3 and game.row_rounds[2] == 0, "second full round shoots primary once and row neighbor once")
	check(game.projectiles[-1].damage == 28 and game.projectiles[-2].damage == 20, "linked shots use each plant's own rank")
	check(c.windup < 0, "pea link cannot cross rows")
	game.control.select(a, game.plants)
	for click in 10:
		game.request_controlled_action()
		step(0.1)
		game.release_controlled_action()
	check(game.row_rounds[2] == 0, "rapid incomplete holds do not add linked rounds")
	hold(a, 0.95)
	step(0.37)
	game.control.select(b, game.plants)
	check(game.row_rounds[2] == 1, "changing primary preserves the shared row counter")
	hold(b, 0.65)
	step(0.37)
	check(game.row_rounds[2] == 0, "a different primary can finish the same row round")
	plant("peashooter", Vector2i(5, 2))
	plant("peashooter", Vector2i(7, 2))
	check(game.Rules.chain_rounds(game.pea_members(2).size()) == 3, "four row members require three full rounds")
	check(game.Rules.chain_rounds(9) == 4, "large rows have a bounded four-round threshold")
	game.row_rounds[2] = 2
	for member in game.pea_members(2).duplicate(): game._remove_entity(game.plants, member)
	check(game.row_rounds[2] == 0 and game.control.selected_plant.is_empty(), "removing the whole row clears stale link state")
	game.free()
	await process_frame
	print("Plant network checks: %d; failures: %d" % [checks, failures])
	quit(failures)
