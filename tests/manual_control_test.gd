extends SceneTree
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

func step(game: Node, seconds: float) -> void:
	for tick in roundi(seconds * 60): game.simulate(1.0 / 60.0)

func key(code: Key, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	return event

func run_tests() -> void:
	seed(1051)
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	check(game.control.enabled, "Mod defaults to manual mode")
	game.try_plant("peashooter", Vector2i(1, 0))
	var first: Dictionary = game.plants[-1]
	check(game.control.selected_plant == first, "new shooter is immediately selected")
	check(game.control_marker.visible and game.control_marker.z_index > first.art.z_index, "selected cell marker renders above the lawn and plant")
	var target: Dictionary = game.spawn_zombie(0, false, 700)
	step(game, 1.0)
	check(game.projectiles.is_empty() and first.windup < 0 and target.hp == 200, "manual shooter stays idle even with a zombie ahead")
	game._input(key(KEY_F))
	check(first.windup > 0 and first.art.get_meta("view").head.current_animation == "shooting", "F starts the existing shooting animation and windup")
	game._input(key(KEY_F, false))
	check(not game.control.fire_held, "releasing F clears held fire")
	check(not game.request_controlled_action(), "repeated command cannot bypass windup or cooldown")
	step(game, 0.2)
	check(game.projectiles.is_empty(), "manual windup does not release a pea early")
	step(game, 0.2)
	check(game.projectiles.size() == 1 and first.windup < 0, "manual command releases exactly one pea after windup")
	check(not game.request_controlled_action(), "cooldown still blocks another shot after release")
	step(game, 1.6)
	check(target.hp == 180, "manual pea flies and hits using real projectile collision")
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(1, 2))
	var second: Dictionary = game.plants[-1]
	check(game.control.selected_plant == second, "planting another shooter transfers selection")
	game.seed_buttons.peashooter.grab_focus()
	Input.parse_input_event(key(KEY_TAB))
	Input.flush_buffered_events()
	for frame in 2: await process_frame
	check(game.control.selected_plant == first, "Tab cycles shooters even when a seed button has GUI focus")
	check(not game.mode_button.get_global_rect().intersects(game.pause_button.get_global_rect()), "actual themed mode button does not overlap the menu")
	Input.parse_input_event(key(KEY_TAB, false))
	game.handle_click(game.cell_center(second.cell))
	check(game.control.selected_plant == second, "clicking an existing shooter transfers control")
	first.attack = 1.0
	game.control.select(first, game.plants)
	game.control.select(second, game.plants)
	game.control.select(first, game.plants)
	check(first.attack == 1.0 and not game.request_controlled_action(), "selection switching cannot reset per-plant cooldown")
	var sun: Dictionary = game.spawn_sun(game.cell_center(second.cell))
	var previous_sun: int = game.sun_count
	game.handle_click(sun.position)
	check(game.sun_count == previous_sun + 25 and game.control.selected_plant == first, "overlapping sun collection takes priority over takeover")
	game.select_seed("wallnut")
	check(game.control.selected_plant.is_empty() and game.selected == "wallnut", "seed selection suspends takeover")
	game.handle_click(game.cell_center(Vector2i(3, 3)))
	check(game.plants[-1].kind == "wallnut", "original planting interaction remains available")
	check(not game.control.select(game.plants[-1], game.plants), "passive wallnut is not forced into manual fire")
	game.try_plant("sunflower", Vector2i(0, 1))
	check(not game.control.select(game.plants[-1], game.plants), "sunflower retains its separate automatic role")
	game.select_seed("")
	game.control.select(first, game.plants)
	first.attack = 0
	game.control.fire_held = true
	game.toggle_pause()
	check(game.paused and not game.control.fire_held, "pause clears held input")
	check(not game.control_marker.visible, "pause hides control overlay")
	var elapsed: float = game.elapsed
	check(not game.request_controlled_action(), "paused game rejects manual attacks")
	game.simulate(1.0)
	check(game.elapsed == elapsed and first.windup < 0, "pause freezes manual action clocks")
	game.toggle_pause()
	step(game, 0.1)
	check(first.windup < 0, "unpausing does not replay stale held input")
	game._input(key(KEY_F))
	step(game, 3.3)
	game._input(key(KEY_F, false))
	check(target.hp <= 140, "held F produces repeated shots at the normal cooldown")
	game.control.select(second, game.plants)
	game.select_seed("shovel")
	game.handle_click(game.cell_center(second.cell))
	check(not game.plants.has(second) and game.control.selected_plant.is_empty(), "shoveling releases the selected plant safely")
	check(not game.request_controlled_action(), "missing selection cannot fire")
	game.control.select(first, game.plants)
	first.hp = 1
	game.spawn_zombie(0, false, game.cell_center(first.cell).x + 36)
	step(game, 0.1)
	check(not game.plants.has(first) and game.control.selected_plant.is_empty(), "zombie killing a controlled plant clears takeover")
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(1, 4))
	var survivor: Dictionary = game.plants[-1]
	game.spawn_zombie(4, false, 700)
	game.toggle_control_mode()
	check(not game.control.enabled and game.control.selected_plant.is_empty(), "automatic mode releases control")
	check(not game.control_marker.visible, "automatic mode hides manual selection overlay")
	step(game, 0.5)
	var lane_peas := 0
	for pea in game.projectiles:
		if pea.row == 4: lane_peas += 1
	check(lane_peas == 1, "automatic comparison mode keeps original enemy-triggered shooting")
	game.toggle_control_mode()
	check(game.control.enabled, "mode can return to manual without reloading the level")
	check(not game.request_controlled_action(), "manual mode requires a fresh selection")
	game.control.select(survivor, game.plants)
	game._finish("胜利！", "test")
	check(game.control.selected_plant.is_empty() and not game.request_controlled_action(), "result screen clears control and rejects attacks")
	game.free()
	await process_frame
	print("Manual control checks: %d; failures: %d" % [checks, failures])
	quit(failures)
