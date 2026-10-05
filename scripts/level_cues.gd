extends Node
## Announcements share the simulation clock, stop on pause, and fire once.
const INTRO_DURATION := 3.0
var game: Node2D
var intro_time := 0.0
var intro_started := false
var intro_done := false
var fired: Dictionary = {}
var banner: Label
var banner_time := 0.0
var voice: AudioStreamPlayer
var alarm: AudioStreamPlayer

func setup(owner_game: Node2D) -> void:
	game = owner_game
	voice = AudioStreamPlayer.new()
	add_child(voice)
	alarm = AudioStreamPlayer.new()
	add_child(alarm)
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	banner = Label.new()
	banner.position = Vector2(game.BOARD_WIDTH / 2 - 330, 265)
	banner.size = Vector2(660, 95)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_font_size_override("font_size", 42)
	banner.add_theme_color_override("font_color", Color(1, 0.22, 0.08))
	banner.add_theme_color_override("font_outline_color", Color(0.13, 0.04, 0.01))
	banner.add_theme_constant_override("outline_size", 5)
	layer.add_child(banner)
	banner.hide()

func play_cue(name: String) -> void:
	if game.silent: return
	var player: AudioStreamPlayer = alarm if name == "siren" else voice
	player.stream = load("res://assets/sounds/%s.ogg" % name)
	player.volume_db = -6
	player.play()

func update_intro(delta: float) -> bool:
	if intro_done: return false
	if not intro_started:
		intro_started = true
		play_cue("readysetplant")
	intro_time = minf(INTRO_DURATION, intro_time + delta)
	banner.show()
	banner.text = "准备…" if intro_time < 1 else ("开始…" if intro_time < 2 else "种植！")
	if intro_time >= INTRO_DURATION:
		intro_done = true
		hide_banner()
	return true

func announce(key: String, text: String, sound: String, duration := 3.0) -> void:
	if fired.has(key): return
	fired[key] = true
	banner.text = text
	banner.show()
	banner_time = duration
	play_cue(sound)

func update_waves(previous: float, next: float) -> void:
	if game.schedule.is_empty(): return
	var first: float = game.schedule[0].time
	var last_wave: int = game.schedule[-1].wave
	var final_start := INF
	for entry in game.schedule:
		if entry.wave == last_wave: final_start = minf(final_start, entry.time)
	if previous <= first and next >= first:
		announce("first", "僵尸来了！", "awooga")
	if previous <= final_start - 5 and next >= final_start - 5:
		announce("huge", "一大波僵尸即将来袭！", "hugewave", 4)
	if previous <= final_start and next >= final_start:
		announce("final", "最后一波！", "siren")
	if previous <= final_start + 0.6 and next >= final_start + 0.6 and not fired.has("final_voice"):
		fired["final_voice"] = true
		play_cue("finalwave")

func update_banner(delta: float) -> void:
	if banner_time <= 0: return
	banner_time = maxf(0, banner_time - delta)
	if banner_time <= 0: hide_banner()

func hide_banner() -> void:
	banner.hide()
	banner_time = 0.0
