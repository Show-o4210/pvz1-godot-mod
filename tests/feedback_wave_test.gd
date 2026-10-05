extends SceneTree
class SoundProbe:
	extends "res://scripts/mod_game.gd"
	var samples: Array[String] = []
	func _play_sound(name: String) -> void:
		samples.append(name)
		super._play_sound(name)

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
	game = SoundProbe.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.automatic_spawns = false
	game.silent = true
	game.sun_count = 1000

func run_tests() -> void:
	fresh()
	for name in ["shovel", "plant2", "tap2", "gulp", "readysetplant", "awooga", "hugewave", "siren", "finalwave"]:
		var audio: AudioStream = load("res://assets/sounds/%s.ogg" % name)
		check(audio != null and audio.get_length() > 0, "original %s sample imports and decodes" % name)
	game.select_seed("shovel")
	check(game.samples[-1] == "shovel", "lifting shovel plays its distinct original sound")
	game.cancel_selection()
	check(game.samples[-1] == "tap2" and game.selected.is_empty(), "cancelling shovel plays original drop sound")
	game.select_seed("peashooter")
	check(game.samples[-1] == "seedlift", "lifting a seed retains its own sound")
	game.select_seed("peashooter")
	check(game.selected.is_empty() and game.samples[-1] == "tap2", "clicking the selected card again cancels with drop sound")
	game.select_seed("sunflower")
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	game._unhandled_input(right)
	check(game.samples[-1] == "tap2" and game.selected.is_empty(), "right-click cancels the seed with sound")
	game.samples.clear()
	game.try_plant("sunflower", Vector2i(1, 2))
	check(game.samples == ["plant"], "successful planting never adds a spurious cancellation sound")
	game.select_seed("shovel")
	game.samples.clear()
	game.handle_click(game.cell_center(Vector2i(1, 2)))
	check(game.samples == ["plant2"] and game.plants.is_empty(), "digging uses original plant2 rather than planting or drop")
	game.select_seed("shovel")
	game.samples.clear()
	game.handle_click(game.cell_center(Vector2i(1, 2)))
	check(game.samples == ["tap2"], "using shovel on empty ground returns it with drop sound")
	game.cooldowns.sunflower = 0
	game.try_plant("sunflower", Vector2i(3, 2))
	var flower: Dictionary = game.plants[-1]
	flower.hp = 5
	game.spawn_zombie(2, false, game.cell_center(flower.cell).x + 30)
	game.samples.clear()
	game.simulate(0.1)
	check(game.samples.count("gulp") == 1 and not game.plants.has(flower), "a zombie consuming the final plant health plays gulp once")
	game.samples.clear()
	game.simulate(0.1)
	check(not game.samples.has("gulp"), "dead plant cannot trigger repeated gulp")
	fresh()
	game.try_plant("peashooter", Vector2i(2, 2))
	var pea: Dictionary = game.plants[-1]
	var expected: Vector2 = pea.art.get_meta("view").muzzle_position()
	game.begin_plant_attack(pea)
	game.simulate(0.36)
	check(absf(game.projectiles[0].art.global_position.y - expected.y) < 0.01, "shifted board still releases a pea at the visible mouth")
	var zombie: Dictionary = game.spawn_zombie(2, false, 720)
	var hand: Sprite2D = zombie.art.get_node("Zombie_outerarm_hand")
	expected = hand.to_global(hand.texture.get_size() * 0.5)
	game.damage_zombie(zombie, 70)
	check(game.effects[-1].art.global_position.is_equal_approx(expected), "detached arm gets the board offset exactly once")
	var sun: Dictionary = game.spawn_sun(Vector2(500, 400))
	expected = sun.art.global_position
	game.collect_sun(sun)
	check(sun.art.global_position.is_equal_approx(expected), "sun flight crosses the shifted board and HUD without teleporting")
	game.simulate(1)
	check(sun.art.global_position.is_equal_approx(game.sun_collection_target()), "shifted-board sun still arrives at the top toolbar slot")
	fresh()
	game.automatic_spawns = true
	game.simulate(0.5)
	check(game.elapsed == 0 and game.level_cues.banner.text == "准备…", "intro shows Ready while freezing the combat clock")
	game.toggle_pause()
	var intro: float = game.level_cues.intro_time
	game.simulate(1)
	check(game.level_cues.intro_time == intro, "pause freezes the intro countdown")
	game.toggle_pause()
	game.simulate(0.6)
	check(game.level_cues.banner.text == "开始…", "intro advances to Set")
	game.simulate(1)
	check(game.level_cues.banner.text == "种植！", "intro advances to Plant")
	game.simulate(0.9)
	check(game.level_cues.intro_done and game.elapsed == 0 and not game.level_cues.banner.visible, "intro ends once without shifting the authored battle schedule")
	game.silent = false
	game.elapsed = 24.99
	game.simulate(0.02)
	check(game.level_cues.fired.has("first") and game.level_cues.voice.stream.resource_path.ends_with("awooga.ogg"), "first authored wave shows Zombies Coming and plays original alarm")
	game.simulate(0.02)
	check(game.level_cues.fired.size() == 1, "first-wave announcement cannot repeat every frame")
	game.elapsed = 106.99
	game.spawn_index = 8
	game.simulate(0.02)
	check(game.level_cues.banner.text == "一大波僵尸即将来袭！" and game.level_cues.voice.stream.resource_path.ends_with("hugewave.ogg"), "last wave gets its warning five seconds beforehand")
	game.elapsed = 111.99
	game.simulate(0.02)
	check(game.level_cues.banner.text == "最后一波！" and game.level_cues.alarm.stream.resource_path.ends_with("siren.ogg"), "final wave shows its banner and separate siren")
	game.simulate(0.6)
	check(game.level_cues.voice.stream.resource_path.ends_with("finalwave.ogg") and game.level_cues.fired.has("final_voice"), "final-wave voice follows the siren without replacing its audio player")
	game.toggle_pause()
	var remaining: float = game.level_cues.banner_time
	game.simulate(2)
	check(game.level_cues.banner_time == remaining and game.level_cues.voice.stream_paused and game.level_cues.alarm.stream_paused, "pause freezes wave text and both announcement audio players")
	game.toggle_pause()
	game.simulate(3)
	check(not game.level_cues.banner.visible, "final announcement expires without stopping ordinary combat")
	game._finish("胜利！", "test")
	check(not game.level_cues.banner.visible and not game.level_cues.voice.playing and not game.level_cues.alarm.playing, "result clears announcements and their audio")
	game.free()
	# Let the audio mixer retire stopped Ogg playback before fast headless exit.
	await create_timer(0.2).timeout
	print("Feedback/wave checks: %d; failures: %d" % [checks, failures])
	quit(failures)
