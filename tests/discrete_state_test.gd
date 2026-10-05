extends SceneTree
## Regressions for persistent discrete pose state across blended transitions.
const DiscreteState := preload("res://scripts/reanim_discrete_state.gd")
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
	var zombie: Dictionary = game.spawn_zombie(3, false, 650)
	var view = zombie.art.get_meta("view")
	var hand: Sprite2D = zombie.art.get_node("Zombie_outerarm_hand")
	var body: Sprite2D = zombie.art.get_node("Zombie_body")
	for phase in [0.0, 0.2, 0.85, 2.4]:
		view.play("walk")
		view.update(phase)
		var previous_pose := body.transform
		view.play("eat")
		check(hand.texture.resource_path.ends_with("Zombie_outerarm_hand2.png"), "bite starts with its open hand at phase %s" % phase)
		check(body.transform.is_equal_approx(previous_pose), "texture switching preserves smooth body blend at phase %s" % phase)
		view.update(0.03)
		check(hand.texture.resource_path.ends_with("Zombie_outerarm_hand2.png"), "outgoing walk cannot overwrite bite hand during blend")
		view.update(0.21)
		view.play("walk")
		check(hand.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "resuming walk immediately restores hanging hand")
		view.update(0.04)
		check(hand.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "outgoing bite cannot overwrite walk hand during blend")
		view.update(4.5)
		check(hand.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "walk hand remains correct beyond a complete gait loop")
	view.arm_lost = true
	view.head_lost = true
	for clip in ["eat", "walk", "death"]:
		view.play(clip)
		view.update(0.1)
		check(not hand.visible and not zombie.art.get_node("Zombie_outerarm_lower").visible and not zombie.art.get_node("anim_head2").visible, "damage masks remain authoritative during %s blend" % clip)
	check(zombie.art.get_node("Zombie_outerarm_upper").texture.resource_path.ends_with("Zombie_outerarm_upper2.png"), "discrete state cannot overwrite damaged upper arm texture")
	game.sun_count = 1000
	game.try_plant("wallnut", Vector2i(4, 1))
	var nut: Dictionary = game.plants[-1]
	var eater: Dictionary = game.spawn_zombie(1, true, game.cell_center(nut.cell).x + 37.1)
	var eater_hand: Sprite2D = eater.art.get_node("Zombie_outerarm_hand")
	game.simulate(0.2)
	check(eater.state == "eat" and eater_hand.texture.resource_path.ends_with("Zombie_outerarm_hand2.png"), "plant contact selects bite hand in the real simulation")
	game._remove_entity(game.plants, nut)
	game.simulate(0.1)
	check(eater.state == "walk" and eater_hand.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "removing the plant restores walk hand in the real simulation")
	game.simulate(0.5)
	check(eater_hand.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "restored hand survives following simulation frames")
	# A nested path and a later key exercise state holding rather than assuming
	# all discrete properties have exactly one key at the start of a clip.
	var actor := Node2D.new()
	root.add_child(actor)
	var parts := Node2D.new()
	parts.name = "Parts"
	actor.add_child(parts)
	var sprite := Sprite2D.new()
	sprite.name = "Hand"
	parts.add_child(sprite)
	var player := AnimationPlayer.new()
	actor.add_child(player)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var animation := Animation.new()
	animation.length = 0.6
	var visible_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(visible_track, NodePath("Parts/Hand:visible"))
	animation.value_track_set_update_mode(visible_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(visible_track, 0.0, true)
	animation.track_insert_key(visible_track, 0.2, false)
	animation.track_insert_key(visible_track, 0.4, true)
	var texture_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(texture_track, NodePath("Parts/Hand:texture"))
	animation.value_track_set_update_mode(texture_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(texture_track, 0.0, load("res://assets/actors/textures/Zombie_outerarm_hand.png"))
	animation.track_insert_key(texture_track, 0.3, load("res://assets/actors/textures/Zombie_outerarm_hand2.png"))
	var library := AnimationLibrary.new()
	library.add_animation("pose", animation)
	player.add_animation_library("", library)
	player.play("pose")
	player.advance(0.1)
	DiscreteState.apply(player)
	check(sprite.visible, "nested visibility state does not apply future key early")
	check(sprite.texture.resource_path.ends_with("Zombie_outerarm_hand.png"), "texture holds its first state before a later authored key")
	player.seek(0.25, true)
	DiscreteState.apply(player)
	check(not sprite.visible, "seeking samples the last visibility key")
	player.seek(0.35, true)
	DiscreteState.apply(player)
	check(sprite.texture.resource_path.ends_with("Zombie_outerarm_hand2.png"), "later texture key is sampled from the current phase")
	player.seek(0.45, true)
	DiscreteState.apply(player)
	check(sprite.visible, "later visibility key restores the part")
	actor.free()
	game.free()
	await process_frame
	print("Discrete state checks: %d; failures: %d" % [checks, failures])
	quit(failures)
