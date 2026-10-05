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
	game.sun_count = 2000

func step(seconds: float) -> void:
	for tick in roundi(seconds * 60): game.simulate(1.0 / 60.0)
	game._update_hud()

func key(code: Key, pressed := true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	return event

func run_tests() -> void:
	fresh()
	game.try_plant("peashooter", Vector2i(1, 2))
	var pea: Dictionary = game.plants[-1]
	var victim: Dictionary = game.spawn_zombie(2, false, 820)
	step(7)
	check(game.projectiles.is_empty() and victim.hp == 200, "planted pea never attacks without a hold")
	check(game.control.selected_plant == pea and not game.control.fire_held, "planting selects without starting an action")
	game.handle_click(game.cell_center(pea.cell))
	step(0.4)
	check(pea.charge > 0 and pea.windup < 0 and game.projectiles.is_empty(), "mouse hold charges before shooting")
	check(game.charge_bar.visible and game.charge_bar.value > 30, "charging has a visible progress bar")
	check(pea.art.scale.x > 1 and (pea.art.position + pea.art.scale * game.Rules.ROOT_PIVOT).is_equal_approx(pea.base_position + game.Rules.ROOT_PIVOT), "feedback enlarges around a stable root")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	game._input(release)
	check(not game.control.fire_held and pea.charge == 0 and not game.charge_bar.visible, "mouse release cancels incomplete charge")
	step(1)
	check(game.projectiles.is_empty() and pea.art.scale == Vector2.ONE, "cancelled charge never fires later and restores scale")
	game._input(key(KEY_F))
	step(0.96)
	check(pea.windup > 0 and game.projectiles.is_empty(), "completed charge begins the existing shooting windup")
	game._input(key(KEY_F, false))
	step(0.37)
	check(game.projectiles.size() == 1 and game.projectiles[0].damage == 20, "completed action releases one real base-damage projectile")
	step(2)
	check(victim.hp == 180, "charged projectile uses real travel and collision")
	game._input(key(KEY_F))
	step(3.4)
	game._input(key(KEY_F, false))
	step(2)
	check(victim.hp <= 140, "continuous hold completes repeated attack rounds")
	game.handle_click(game.cell_center(pea.cell))
	step(0.2)
	var motion := InputEventMouseMotion.new()
	motion.position = game.cell_center(Vector2i(2, 2))
	game._input(motion)
	check(not game.control.fire_held and pea.charge == 0, "leaving the original fixed cell cancels mouse hold")
	game._input(key(KEY_F))
	step(0.2)
	game.toggle_pause()
	var clock: float = game.elapsed
	step(1)
	check(game.elapsed == clock and not game.control.fire_held and pea.charge == 0, "pause cancels hold and freezes the simulation")
	check(not game.charge_bar.visible and not game.control_marker.visible, "pause hides charging and selection feedback")
	game.toggle_pause()
	step(0.2)
	check(pea.charge == 0, "unpause requires a fresh input")
	game.request_controlled_action()
	step(0.2)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.control.fire_held and pea.charge == 0, "window focus loss releases charging")
	fresh()
	game.try_plant("peashooter", Vector2i(1, 2))
	pea = game.plants[-1]
	pea.hp = 155
	pea.attack = 0.2
	pea.charge = 0.1
	game.cooldowns.peashooter = 0
	var funds: int = game.sun_count
	check(game.try_plant("peashooter", pea.cell), "same-species stacking upgrades")
	check(pea.rank == 2 and game.plants.size() == 1 and game.sun_count == funds - 100, "upgrade reuses the plant and charges normal cost")
	check(pea.hp == 155 and pea.attack == 0.2 and pea.charge == 0.1, "upgrade does not heal or reset action state")
	check(not game.try_plant("peashooter", pea.cell), "upgrade respects seed-card cooldown")
	funds = game.sun_count
	check(not game.try_plant("sunflower", pea.cell) and game.sun_count == funds, "different species cannot stack or spend resources")
	game.cooldowns.peashooter = 0
	game.sun_count = 0
	check(not game.try_plant("peashooter", pea.cell) and pea.rank == 2, "insufficient resources reject upgrade")
	game.sun_count = 1000
	check(game.try_plant("peashooter", pea.cell) and pea.rank == 3, "third rank is reachable")
	game.cooldowns.peashooter = 0
	funds = game.sun_count
	check(not game.try_plant("peashooter", pea.cell) and game.sun_count == funds, "max rank rejects further cost")
	check(game.Rules.charge_time(pea) < 0.95, "rank reduces required hold time")
	pea.attack = 0
	pea.charge = 0
	game.request_controlled_action()
	step(0.67)
	game.release_controlled_action()
	step(0.37)
	check(game.projectiles.size() == 1 and game.projectiles[0].damage == 28 and game.projectiles[0].art.scale.x > 1, "third-rank shot carries stronger damage and visible feedback")
	fresh()
	game.try_plant("sunflower", Vector2i(0, 2))
	var flower: Dictionary = game.plants[-1]
	step(30)
	check(game.suns.is_empty(), "planted sunflower has no passive production in manual mode")
	game.handle_click(game.cell_center(flower.cell))
	step(2.3)
	check(game.suns.is_empty() and game.charge_bar.value > 90, "sunflower must finish its full hold")
	step(0.15)
	game.release_controlled_action()
	check(game.suns.is_empty() and flower.sun_state == "work", "completed sunflower charge activates Work without instant sun")
	step(5)
	check(game.suns.is_empty() and flower.sun_ready < 3.1, "first rank progresses automatic production after activation")
	step(3.05)
	check(game.suns.size() == 1 and game.suns[0].value == 25, "working sunflower automatically produces a collectible 25 sun")
	game.request_controlled_action()
	step(9)
	game.release_controlled_action()
	check(game.suns.size() >= 2, "holding sunflower continues into later production rounds")
	game.try_plant("peashooter", Vector2i(1, 2))
	pea = game.plants[-1]
	game.control.select(flower, game.plants)
	game.seed_buttons.peashooter.grab_focus()
	Input.parse_input_event(key(KEY_TAB))
	Input.flush_buffered_events()
	for frame in 2: await process_frame
	check(game.control.selected_plant == pea and not game.control.fire_held, "Tab cycles both species without GUI focus starting a hold")
	check(not game.mode_button.get_global_rect().intersects(game.pause_button.get_global_rect()), "mode button and menu stay separate")
	game.request_controlled_action()
	for old_sun in game.suns.duplicate(): game.collect_sun(old_sun)
	var sun: Dictionary = game.spawn_sun(game.cell_center(flower.cell))
	sun["value"] = 18
	funds = game.sun_count
	game.handle_click(sun.position)
	check(game.sun_count == funds + 18 and not game.control.fire_held and game.control.selected_plant == pea, "variable-value sun collection takes priority and stops charging")
	game.select_seed("wallnut")
	check(game.control.selected_plant.is_empty(), "seed selection suspends plant control")
	game.handle_click(game.cell_center(Vector2i(4, 2)))
	check(game.plants[-1].kind == "wallnut" and not game.control.can_control(game.plants[-1]), "passive wallnut keeps its original role")
	game.control.select(pea, game.plants)
	game.request_controlled_action()
	game._remove_entity(game.plants, pea)
	step(0.02)
	check(game.control.selected_plant.is_empty() and not game.control.fire_held and not game.charge_bar.visible, "plant removal safely clears input and feedback")
	for remaining_sun in game.suns.duplicate(): game.collect_sun(remaining_sun)
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(1, 4))
	game.spawn_zombie(4, false, 820)
	game.toggle_control_mode()
	check(not game.control.enabled and game.control.selected_plant.is_empty(), "automatic comparison mode releases control")
	step(7)
	check(game.suns.size() == 1, "automatic comparison restores sunflower without a backlog burst")
	check(not game.projectiles.is_empty(), "automatic comparison restores enemy-triggered shooting")
	game.toggle_control_mode()
	check(game.control.enabled and not game.request_controlled_action(), "returning to manual requires fresh selection")
	game.control.select(flower, game.plants)
	game.request_controlled_action()
	game._finish("胜利！", "test")
	check(not game.control.fire_held and game.control.selected_plant.is_empty() and not game.charge_bar.visible, "result screen cancels active control")
	game.free()
	await process_frame
	print("Charged action checks: %d; failures: %d" % [checks, failures])
	quit(failures)
