extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, description: String) -> void:
	checks += 1
	if value: print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func run_tests() -> void:
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000
	game.try_plant("peashooter", Vector2i(1, 2))
	var plant: Dictionary = game.plants[0]
	var view = plant.art.get_meta("view")
	var head: Sprite2D = view.attachment.get_node("anim_face")
	var stem: Node2D = plant.art.get_node("anim_stem")
	view.head.seek(0, true)
	var head_start := head.global_position
	var stem_start := stem.position
	view.player.seek(0.65, true)
	view.attachment.sync_pose()
	check((head.global_position - head_start).is_equal_approx(stem.position - stem_start), "head inherits body stem sway without restarting its own animation")
	check(head.global_position.distance_to(head_start) > 3, "head and body have visible shared sway")
	var bind_pose: Transform2D = view.attachment.bind_inverse.affine_inverse()
	var original_stem := stem.transform
	stem.transform = Transform2D(0.35, Vector2(45, 41)).scaled(Vector2(1.1, 0.9))
	view.attachment.sync_pose()
	check((view.attachment.transform * bind_pose).is_equal_approx(stem.transform), "attachment also inherits anchor rotation and scale")
	stem.transform = original_stem
	view.attachment.sync_pose()
	view.shoot()
	view.update(0.3)
	check(view.attachment.transform.origin.distance_to(Vector2.ZERO) > 1, "shooting keeps the head bound to the moving stem")
	view.blink_time = 0
	view.shoot_time = 0
	view.update(0.01)
	check(view.eyelids.get_animation("blink").track_get_path(0).get_name(0) == "HeadAttachment", "eyelids share the head attachment")
	var zombie: Dictionary = game.spawn_zombie(3, false, 650)
	var zview = zombie.art.get_meta("view")
	var jaw: Sprite2D = zombie.art.get_node("anim_head2")
	check(jaw.visible and jaw.texture.resource_path.ends_with("Zombie_jaw.png"), "normal zombie includes the original jaw")
	zview.update(0.4)
	check(jaw.visible and jaw.position != Vector2(13.5, 40.6), "jaw animates together with the walking head")
	var motion = zview.motion
	var minimum := INF
	var maximum := 0.0
	var travelled := 0.0
	var cycle_time: float = motion.length / motion.playback_rate
	for tick in 600:
		var step: float = motion.displacement(tick * cycle_time / 600 * motion.playback_rate, cycle_time / 600)
		minimum = minf(minimum, step)
		maximum = maxf(maximum, step)
		travelled += step
	check(maximum > minimum * 3 and minimum >= 0, "walking displacement follows footfalls rather than constant sliding")
	check(absf(travelled - motion.distance) < 0.0001, "one gait cycle integrates the full original ground distance")
	check(absf(travelled / cycle_time - 12) < 0.0001, "gait preserves the existing average combat speed")
	var phase: float = motion.length - 0.01
	var whole: float = motion.displacement(phase, 0.2)
	var split: float = motion.displacement(phase, 0.1) + motion.displacement(phase + 0.1 * motion.playback_rate, 0.1)
	check(absf(whole - split) < 0.0001 and whole < 6, "loop wrap is continuous and independent of tick size")
	zview.player.seek(1.0, true)
	var body: Sprite2D = zombie.art.get_node("Zombie_body")
	var old_pose := body.transform
	zview.play("eat")
	check(body.transform.is_equal_approx(old_pose), "walk-to-bite transition does not snap the body pose")
	zview.update(0.2)
	check(not body.transform.is_equal_approx(old_pose) and jaw.visible, "bite transition blends to the new pose with the jaw intact")
	game.damage_zombie(zombie, 150)
	check(not jaw.visible and not zombie.art.get_node("anim_tongue").visible, "losing the head also removes jaw and tongue")
	game.try_plant("wallnut", Vector2i(3, 1))
	var nut: Dictionary = game.plants[-1]
	var contact: float = game.cell_center(nut.cell).x + 37
	var eater: Dictionary = game.spawn_zombie(1, false, contact + 0.25)
	game.simulate(0.2)
	check(absf(eater.x - contact) < 0.001 and eater.state == "eat", "arrival stops at plant contact without overshooting")
	check(nut.hp > 3980 and nut.hp < 4000, "arrival only bites for the remaining fraction of the tick")
	game.simulate(0.5)
	check(absf(eater.x - contact) < 0.001, "biting zombie keeps a stable world position")
	game._remove_entity(game.plants, nut)
	game.simulate(0.1)
	check(eater.state == "walk" and eater.x < contact and eater.x > contact - 4, "removing the plant resumes gait smoothly")
	game.free()
	await process_frame
	print("Animation detail checks: %d; failures: %d" % [checks, failures])
	quit(failures)
