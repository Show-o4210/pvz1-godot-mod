extends "res://scripts/game.gd"
## First playable Mod foundation: selected Peashooters receive player fire commands.
const PlantControl := preload("res://scripts/plant_control.gd")
var control = PlantControl.new()
var control_label: Label
var mode_button: Button
var control_marker: Line2D

func _build_hud() -> void:
	super._build_hud()
	var layer := CanvasLayer.new()
	add_child(layer)
	control_label = _label(layer, Vector2(275, 10), Vector2(166, 58), 14)
	mode_button = _button(layer, "切换自动", Vector2(538, 3), Vector2(130, 46))
	mode_button.add_theme_font_size_override("font_size", 14)
	mode_button.tooltip_text = "切换手动操控和 v1 自动射击，便于比较体验"
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(toggle_control_mode)
	# Parent _draw() is under the background Sprite2D child; use an explicit
	# overlay with its own z order so the controlled cell is actually visible.
	control_marker = Line2D.new()
	control_marker.z_index = 180
	control_marker.width = 2.0
	control_marker.default_color = Color(1, 0.9, 0.3, 0.85)
	control_marker.antialiased = true
	control_marker.closed = true
	control_marker.points = PackedVector2Array([Vector2(3, 3), Vector2(CELL_SIZE.x - 3, 3), CELL_SIZE - Vector2(3, 3), Vector2(3, CELL_SIZE.y - 3)])
	add_child(control_marker)

func _input(event: InputEvent) -> void:
	# Handle Tab before GUI focus navigation consumes it after clicking a seed.
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo and not paused and result.is_empty():
		select_seed("")
		control.cycle(plants)
		_update_hud()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.keycode == KEY_F:
		if event.echo: return
		control.fire_held = event.pressed and control.enabled and not paused and result.is_empty()
		if control.fire_held: request_controlled_action()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not paused and result.is_empty():
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			control.clear()
	super._unhandled_input(event)

func handle_click(pos: Vector2) -> void:
	# Let the original path handle sun priority, seed placement and the shovel.
	var collecting_sun := false
	for sun in suns:
		if pos.distance_to(sun.position) < 33:
			collecting_sun = true
			break
	if not paused and result.is_empty() and selected.is_empty() and not collecting_sun:
		var cell := screen_to_cell(pos)
		for plant in plants:
			if plant.cell == cell and control.select(plant, plants):
				_update_hud()
				return
	super.handle_click(pos)

func select_seed(kind: String) -> void:
	super.select_seed(kind)
	if not kind.is_empty() and selected == kind:
		control.clear()
		_update_hud()

func try_plant(kind: String, cell: Vector2i) -> bool:
	if not super.try_plant(kind, cell): return false
	var plant: Dictionary = plants[-1]
	if control.requires_input(plant):
		plant.attack = 0.0
		control.select(plant, plants)
		_update_hud()
	return true

func should_auto_attack(plant: Dictionary) -> bool:
	return not control.requires_input(plant)

func request_controlled_action() -> bool:
	control.validate(plants)
	if not control.enabled or control.selected_plant.is_empty(): return false
	return begin_plant_attack(control.selected_plant)

func _update_plants(delta: float) -> void:
	control.validate(plants)
	super._update_plants(delta)
	if control.fire_held: request_controlled_action()

func _remove_entity(collection: Array[Dictionary], entity: Dictionary) -> void:
	super._remove_entity(collection, entity)
	control.validate(plants)

func toggle_control_mode() -> void:
	if paused or not result.is_empty(): return
	control.enabled = not control.enabled
	control.clear()
	_update_hud()

func toggle_pause() -> void:
	control.fire_held = false
	super.toggle_pause()
	_update_hud()

func _finish(title: String, message: String) -> void:
	control.clear()
	super._finish(title, message)
	_update_hud()

func _update_hud() -> void:
	super._update_hud()
	if not is_instance_valid(control_label): return
	control.validate(plants)
	mode_button.disabled = paused or not result.is_empty()
	mode_button.text = "切换自动" if control.enabled else "切换手动"
	if not control.enabled:
		control_label.text = "自动模式\n植物自行射击"
	elif control.selected_plant.is_empty():
		control_label.text = "手动模式 · 等待接管\n点击射手或按 Tab"
	else:
		var plant: Dictionary = control.selected_plant
		var state := "射击就绪"
		if plant.windup >= 0: state = "正在发射"
		elif plant.attack > 0: state = "冷却 %.1f 秒" % plant.attack
		control_label.text = "射手 · 第 %d 行\n%s · F 开火" % [plant.cell.y + 1, state]
	if result.is_empty():
		hint_label.text = "已暂停 · 空格继续" if paused else ("点击接管 · F开火 · Tab切换 · 空格暂停" if control.enabled else "1/2/3 选卡 · 4 铲子 · 空格暂停")
	control_marker.visible = control.enabled and not control.selected_plant.is_empty() and not paused and result.is_empty()
	if control_marker.visible:
		control_marker.position = GRID_ORIGIN + Vector2(control.selected_plant.cell) * CELL_SIZE
