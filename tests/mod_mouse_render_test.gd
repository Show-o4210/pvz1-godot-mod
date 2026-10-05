extends SceneTree
var checks := 0
var failures := 0
var game: Node
var viewport: SubViewport

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, description: String) -> void:
	checks += 1
	if value: print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func step(seconds: float) -> void:
	for tick in roundi(seconds * 60): game.simulate(1.0 / 60.0)
	game._update_hud()

func mouse(pos: Vector2, pressed: bool, hud := false) -> void:
	if not hud: pos = game.to_global(pos)
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	viewport.push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.position = pos
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	viewport.push_input(event, true)

func snapshot(name: String) -> Image:
	game._update_hud()
	for frame in 2: await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	result.save_png("res://build/" + name + ".png")
	return result

func run_tests() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	viewport = SubViewport.new()
	viewport.size = Vector2i(900, 640)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	game = load("res://scenes/mod_game.tscn").instantiate()
	viewport.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("peashooter", Vector2i(1, 0))
	var pea: Dictionary = game.plants[-1]
	game.cooldowns.peashooter = 0
	game.try_plant("peashooter", Vector2i(3, 0))
	game.try_plant("sunflower", Vector2i(1, 2))
	var flower: Dictionary = game.plants[-1]
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", flower.cell)
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", Vector2i(0, 2))
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", Vector2i(1, 3))
	for frame in 2: await process_frame
	mouse(game.cell_center(pea.cell), true)
	step(0.4)
	check(game.control.selected_plant == pea and game.control.mouse_held and pea.charge > 0, "real viewport mouse press selects and charges the clicked pea")
	var img := await snapshot("mod-charging")
	var bar_pos: Vector2 = game.charge_bar.global_position
	var pixel := img.get_pixel(roundi(bar_pos.x + 5), roundi(bar_pos.y + 4))
	check(absf(pixel.r - 0.45) < 0.03 and pixel.g > 0.9 and pixel.b < 0.3, "GPU renders the progress fill above the lawn")
	check(bar_pos.y >= 100, "first-row progress stays below the inset seed bank")
	check(game.charge_bar.size.y <= 10, "actual themed progress bar stays thin without covering the face")
	mouse(Vector2(600, 25), false, true)
	check(not game.control.fire_held and pea.charge == 0, "mouse release over GUI still cancels charging")
	game.cooldowns.sunflower = 0
	game._update_hud()
	mouse(Vector2(165, 35), true, true)
	mouse(Vector2(165, 35), false, true)
	check(game.selected == "sunflower" and game.control.selected_plant.is_empty(), "real seed-card click selects planting instead of charging")
	mouse(game.cell_center(flower.cell), true)
	mouse(game.cell_center(flower.cell), false)
	check(flower.rank == 3 and not game.control.fire_held, "real card stacking upgrades without accidentally starting hold")
	mouse(game.cell_center(flower.cell), true)
	step(2.4)
	mouse(game.cell_center(flower.cell), false)
	check(game.suns.is_empty() and flower.sun_state == "work" and game.plants[-1].sun_state == "weak_work", "real sunflower hold activates Work and neighboring Weak Work without instant sun")
	step(8.05)
	check(game.suns.size() == 3 and game.suns[0].value == 35, "activated plants produce while the mouse is released")
	await snapshot("mod-supply")
	# Real mouse-driven completed rounds launch one synchronized row volley.
	mouse(game.cell_center(pea.cell), true)
	step(3.6)
	mouse(game.cell_center(pea.cell), false)
	check(pea.windup > 0 and game.plants[1].windup > 0 and game.row_energy[0] == 0, "sustained real mouse input completes three-round rank-one volley")
	step(0.37)
	check(game.projectiles.size() >= 2, "mouse-driven linked windups release real synchronized projectiles")
	await snapshot("mod-linked")
	for sun in game.suns.duplicate(): game.collect_sun(sun)
	game.select_seed("shovel")
	mouse(game.cell_center(flower.cell), true)
	mouse(game.cell_center(flower.cell), false)
	check(not game.plants.has(flower), "real shovel click removes an upgraded plant")
	game.select_seed("")
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", Vector2i(6, 0))
	var top: Dictionary = game.plants[-1]
	mouse(game.cell_center(top.cell), true)
	step(2.3)
	var hat: Sprite2D = top.rank_hat
	var top_y := INF
	for rank in 3:
		hat.set_rank(rank + 1)
		var rect := hat.get_rect()
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			top_y = minf(top_y, hat.to_global(corner).y)
	hat.set_rank(top.rank)
	check(top_y >= 100, "charged first-row sunflower cap stays below the inset seed bank (top %.2f)" % top_y)
	check(top.rank_badge.visible and top.production_meter.visible and game.charge_bar.visible and game.charge_bar.global_position.y >= 100, "compact layout keeps first-row production and charge feedback visible together")
	mouse(game.cell_center(top.cell), false)
	check(top.rank_badge.visible and top.production_meter.visible and not game.charge_bar.visible, "first-row sunflower restores its stopped production indicators on release")
	await snapshot("mod-top-row")
	viewport.free()
	await process_frame
	print("Mod mouse/GPU checks: %d; failures: %d" % [checks, failures])
	quit(failures)
