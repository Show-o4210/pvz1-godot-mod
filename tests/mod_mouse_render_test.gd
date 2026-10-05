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

func mouse(pos: Vector2, pressed: bool) -> void:
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
	for frame in 2: await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	result.save_png("res://build/" + name + ".png")
	return result

func run_tests() -> void:
	DirAccess.make_dir_recursive_absolute("res://build")
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
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
	var bar_pos: Vector2 = game.charge_bar.position
	var pixel := img.get_pixel(roundi(bar_pos.x + 5), roundi(bar_pos.y + 4))
	check(absf(pixel.r - 0.45) < 0.03 and pixel.g > 0.9 and pixel.b < 0.3, "GPU renders the progress fill above the lawn")
	check(bar_pos.y >= 86, "first-row progress stays below the seed bank")
	check(game.charge_bar.size.y <= 10, "actual themed progress bar stays thin without covering the face")
	mouse(Vector2(600, 25), false)
	check(not game.control.fire_held and pea.charge == 0, "mouse release over GUI still cancels charging")
	game.cooldowns.sunflower = 0
	game._update_hud()
	mouse(Vector2(165, 35), true)
	mouse(Vector2(165, 35), false)
	check(game.selected == "sunflower" and game.control.selected_plant.is_empty(), "real seed-card click selects planting instead of charging")
	mouse(game.cell_center(flower.cell), true)
	mouse(game.cell_center(flower.cell), false)
	check(flower.rank == 3 and not game.control.fire_held, "real card stacking upgrades without accidentally starting hold")
	mouse(game.cell_center(flower.cell), true)
	step(2.4)
	mouse(game.cell_center(flower.cell), false)
	check(game.suns.size() == 3 and flower.auto_until > game.elapsed, "real sunflower hold starts neighboring supply and rank reward")
	await snapshot("mod-supply")
	# Real mouse-driven completed rounds launch one synchronized row volley.
	mouse(game.cell_center(pea.cell), true)
	step(2.65)
	mouse(game.cell_center(pea.cell), false)
	check(game.projectiles.size() >= 3 and game.row_rounds[0] == 0, "sustained real mouse input completes row-linked volleys")
	await snapshot("mod-linked")
	for sun in game.suns.duplicate(): game.collect_sun(sun)
	game.select_seed("shovel")
	mouse(game.cell_center(flower.cell), true)
	mouse(game.cell_center(flower.cell), false)
	check(not game.plants.has(flower), "real shovel click removes an upgraded plant")
	viewport.free()
	await process_frame
	print("Mod mouse/GPU checks: %d; failures: %d" % [checks, failures])
	quit(failures)
