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

func run_tests() -> void:
	var game = load("res://scenes/mod_game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 5000
	for kind in ["peashooter", "sunflower"]:
		game.cooldowns[kind] = 0
		game.try_plant(kind, Vector2i(2, 1 if kind == "sunflower" else 3))
		var plant: Dictionary = game.plants[-1]
		var hat: Sprite2D = plant.rank_hat
		var face: Node2D = plant.art.get_node("HeadAttachment/anim_face" if kind == "peashooter" else "anim_idle")
		check(hat.get_parent() == face and hat.is_visible_in_tree(), kind + " cap is visibly attached to the live face")
		var previous: Texture2D = hat.texture
		for rank in 3:
			if rank > 0:
				game.cooldowns[kind] = 0
				game.try_plant(kind, plant.cell)
				check(hat.texture != previous, kind + " upgrade visibly changes cap rank %d" % (rank + 1))
				previous = hat.texture
			check(absf(hat.region_rect.size.x * hat.scale.x - (40 if kind == "sunflower" else 42)) < 0.01, kind + " cap width stays consistent across ranks")
			var image: Image = hat.texture.get_image()
			check(image.detect_alpha() != Image.ALPHA_NONE and image.get_pixel(0, 0).a == 0, kind + " cap rank %d preserves transparent background" % (rank + 1))
		var bind: Transform2D = hat.transform
		var initial: Vector2 = hat.global_position
		game.control.select(plant, game.plants)
		game.request_controlled_action()
		var max_error := 0.0
		var max_motion := 0.0
		var visible_through_action := true
		for tick in 180:
			game.simulate(1.0 / 60.0)
			var expected: Transform2D = face.global_transform * bind
			max_error = maxf(max_error, expected.origin.distance_to(hat.global_transform.origin))
			max_error = maxf(max_error, expected.x.distance_to(hat.global_transform.x))
			max_motion = maxf(max_motion, initial.distance_to(hat.global_position))
			visible_through_action = visible_through_action and hat.is_visible_in_tree()
		check(max_error < 0.001 and max_motion > 1, kind + " cap follows full animated pose and root-anchored enlargement")
		check(visible_through_action, kind + " cap stays visible through shooting or activation and blink")
		game.release_controlled_action()
		var view = plant.art.get_meta("view")
		view.blink_time = 0
		game.simulate(0.05)
		check((face.global_transform * bind).origin.distance_to(hat.global_position) < 0.001, kind + " blink never separates the cap from the face")
		view.hurt()
		check(hat.material == view.material, kind + " cap shares the plant's damage flash")
		if kind == "sunflower":
			check(plant.rank_badge.text == "WORK" and plant.production_meter.value > 0, "working sunflower has visible state and automatic production progress")
			game._start_sun_window(plant, 40, 0.75)
			plant.full_until = 0
			game.simulate(0.05)
			check(plant.rank_badge.text == "弱 WORK", "linked sunflower has distinct Weak Work feedback")
			plant.linked_until = 0
			plant.auto_until = 0
			game.simulate(0.05)
			check(plant.rank_badge.text == "STOP", "expired sunflower displays Stop without recoloring original art")
			game.toggle_control_mode()
			check(not plant.rank_badge.visible and not plant.production_meter.visible, "automatic comparison hides manual-only state indicators")
			game.toggle_control_mode()
	game.free()
	await process_frame
	print("Rank presentation checks: %d; failures: %d" % [checks, failures])
	quit(failures)
