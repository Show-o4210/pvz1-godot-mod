extends "res://scripts/game.gd"
## Charged actions, ranks and non-recursive networks. Local Mod prototype.
const PlantControl := preload("res://scripts/plant_control.gd")
const Rules := preload("res://scripts/mod_rules.gd")
var control = PlantControl.new()
var control_label: Label
var mode_button: Button
var control_marker: Line2D
var charge_bar: ProgressBar
var row_rounds := [0, 0, 0, 0, 0]

func _build_hud() -> void:
	super._build_hud()
	var layer := CanvasLayer.new()
	add_child(layer)
	control_label = _label(layer, Vector2(270, 7), Vector2(172, 68), 12)
	mode_button = _button(layer, "切换自动", Vector2(538, 3), Vector2(130, 46))
	mode_button.add_theme_font_size_override("font_size", 14)
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(toggle_control_mode)
	control_marker = Line2D.new()
	control_marker.z_index = 180
	control_marker.width = 2
	control_marker.default_color = Color(1, 0.9, 0.3, 0.85)
	control_marker.antialiased = true
	control_marker.closed = true
	control_marker.points = PackedVector2Array([Vector2(3, 3), Vector2(CELL_SIZE.x - 3, 3), CELL_SIZE - Vector2(3, 3), Vector2(3, CELL_SIZE.y - 3)])
	add_child(control_marker)
	charge_bar = ProgressBar.new()
	charge_bar.show_percentage = false
	charge_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge_bar.z_index = 185
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.12, 0.06, 0.95)
	bg.border_color = Color(1, 0.9, 0.45)
	bg.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.95, 0.25)
	charge_bar.add_theme_stylebox_override("background", bg)
	charge_bar.add_theme_stylebox_override("fill", fill)
	charge_bar.add_theme_font_size_override("font_size", 1)
	charge_bar.size = Vector2(60, 9)
	charge_bar.hide()
	add_child(charge_bar)

func _input(event: InputEvent) -> void:
	# Releases must be handled even when the pointer is over GUI controls.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if control.mouse_held: release_controlled_action()
	if event is InputEventMouseMotion and control.mouse_held:
		if control.selected_plant.is_empty() or screen_to_cell(get_global_transform().affine_inverse() * event.position) != control.selected_plant.cell:
			release_controlled_action()
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo and not paused and result.is_empty():
		select_seed("")
		control.cycle(plants)
		_update_hud()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.keycode == KEY_F:
		if event.echo: return
		if event.pressed: request_controlled_action()
		else: release_controlled_action()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: release_controlled_action()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not paused and result.is_empty(): handle_click(get_global_transform().affine_inverse() * event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		control.clear()
	super._unhandled_input(event)

func handle_click(pos: Vector2) -> void:
	var collecting_sun := false
	for sun in suns:
		if pos.distance_to(sun.position) < 33:
			collecting_sun = true
			break
	if not paused and result.is_empty() and selected.is_empty() and not collecting_sun:
		var cell := screen_to_cell(pos)
		for plant in plants:
			if plant.cell == cell and control.select(plant, plants):
				request_controlled_action(true)
				_update_hud()
				return
	if collecting_sun: release_controlled_action()
	super.handle_click(pos)

func select_seed(kind: String) -> void:
	super.select_seed(kind)
	if not kind.is_empty() and selected == kind:
		control.clear()
		_update_hud()

func try_plant(kind: String, cell: Vector2i) -> bool:
	if paused or not result.is_empty() or not DEFINITIONS.has(kind): return false
	for plant in plants:
		if plant.cell != cell: continue
		if kind != plant.kind or not control.can_control(plant) or plant.rank >= Rules.MAX_RANK: return false
		if sun_count < DEFINITIONS[kind].cost or cooldowns[kind] > 0: return false
		sun_count -= DEFINITIONS[kind].cost
		cooldowns[kind] = DEFINITIONS[kind].cooldown
		plant.rank += 1
		plant.pulse = 0.18
		_play_sound("plant")
		select_seed("")
		control.select(plant, plants)
		_update_hud()
		return true
	if not super.try_plant(kind, cell): return false
	var plant: Dictionary = plants[-1]
	plant.merge({"rank": 1, "charge": 0.0, "sun_ready": 0.0, "auto_until": 0.0,
		"full_until": 0.0, "linked_until": 0.0,
		"auto_next": 0.0, "auto_efficiency": 1.0, "sun_fraction": 0.0, "pulse": 0.0,
		"base_position": plant.art.position})
	if control.can_control(plant):
		var badge := Label.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.z_index = 181
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		badge.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.02))
		badge.add_theme_constant_override("outline_size", 3)
		badge.position = cell_center(cell) + Vector2(18, -46)
		add_child(badge)
		plant["rank_badge"] = badge
		plant.attack = 0.0
		control.select(plant, plants)
	_update_hud()
	return true

func should_auto_attack(plant: Dictionary) -> bool:
	return not control.requires_input(plant)

func should_auto_produce(plant: Dictionary) -> bool:
	return not control.requires_input(plant)

func begin_plant_attack(plant: Dictionary) -> bool:
	if not super.begin_plant_attack(plant): return false
	if control.enabled: plant.attack = 0.35
	return true

func configure_plant_pea(pea: Dictionary, plant: Dictionary) -> void:
	var rank: int = plant.get("rank", 1)
	pea["damage"] = Rules.PEA_DAMAGE[rank - 1]
	pea.art.scale = Vector2.ONE * (1.0 + (rank - 1) * 0.1)
	pea.art.modulate = [Color.WHITE, Color(0.9, 1, 0.7), Color(0.7, 1, 1)][rank - 1]

func request_controlled_action(mouse := false) -> bool:
	control.validate(plants)
	if paused or not result.is_empty() or not selected.is_empty() or not control.enabled or control.selected_plant.is_empty(): return false
	control.fire_held = true
	control.mouse_held = mouse
	return true

func release_controlled_action() -> void:
	control.release()
	if is_instance_valid(charge_bar): charge_bar.hide()
	_update_feedback(0)

func _update_plants(delta: float) -> void:
	control.validate(plants)
	super._update_plants(delta)
	for plant in plants:
		if not control.can_control(plant): continue
		plant.sun_ready = maxf(0, plant.sun_ready - delta)
		if control.enabled and plant.kind == "sunflower" and plant.auto_until > 0:
			plant.auto_efficiency = 1.0 if elapsed <= plant.full_until + 0.000001 else Rules.NEIGHBOR_EFFICIENCY
			var manual_ready: bool = control.fire_held and control.selected_plant == plant and plant.charge + delta >= Rules.charge_time(plant)
			if not manual_ready and elapsed <= plant.auto_until + 0.000001 and elapsed >= plant.auto_next and plant.sun_ready <= 0:
				_produce_manual_sun(plant, plant.auto_efficiency)
	if control.fire_held and not control.selected_plant.is_empty():
		var plant: Dictionary = control.selected_plant
		var ready: bool = plant.windup < 0 and plant.attack <= 0 if plant.kind == "peashooter" else true
		if ready:
			plant.charge = minf(plant.charge + delta, Rules.charge_time(plant))
			if plant.charge + 0.000001 >= Rules.charge_time(plant) and (plant.kind == "peashooter" or plant.sun_ready <= 0):
				plant.charge = 0.0
				plant.pulse = 0.18
				if plant.kind == "peashooter": _complete_pea_charge(plant)
				else: _activate_sun_network(plant)
	_update_feedback(delta)

func pea_members(row: int) -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	for plant in plants:
		if plant.kind == "peashooter" and plant.cell.y == row: members.append(plant)
	return members

func _complete_pea_charge(plant: Dictionary) -> void:
	if not begin_plant_attack(plant): return
	var row: int = plant.cell.y
	var members := pea_members(row)
	row_rounds[row] += 1
	if row_rounds[row] >= Rules.chain_rounds(members.size()):
		row_rounds[row] = 0
		for neighbor in members:
			if neighbor != plant and begin_plant_attack(neighbor): neighbor.pulse = 0.18

func sunflower_neighbors(plant: Dictionary) -> Array[Dictionary]:
	var neighbors: Array[Dictionary] = []
	for other in plants:
		var offset: Vector2i = other.cell - plant.cell
		if other != plant and other.kind == "sunflower" and absi(offset.x) <= 1 and absi(offset.y) <= 1:
			neighbors.append(other)
	return neighbors

func _produce_manual_sun(plant: Dictionary, efficiency: float) -> bool:
	if plant.sun_ready > 0: return false
	var amount: float = Rules.SUN_VALUE * efficiency + plant.sun_fraction
	var value := floori(amount + 0.000001)
	plant.sun_fraction = amount - value
	var sun := spawn_sun(cell_center(plant.cell) + Vector2(5, -35))
	sun["value"] = value
	sun["source_cell"] = plant.cell
	plant.sun_ready = Rules.SUN_INTERVAL
	plant.auto_next = elapsed + Rules.SUN_INTERVAL
	plant.pulse = 0.18
	return true

func _start_sun_window(plant: Dictionary, duration: float, efficiency: float) -> void:
	if duration <= 0: return
	var already_active: bool = plant.auto_until > elapsed
	if efficiency >= 1.0: plant.full_until = maxf(plant.full_until, elapsed + duration)
	else: plant.linked_until = maxf(plant.linked_until, elapsed + duration)
	plant.auto_until = maxf(plant.full_until, plant.linked_until)
	plant.auto_efficiency = 1.0 if plant.full_until > elapsed else Rules.NEIGHBOR_EFFICIENCY
	if not already_active: plant.auto_next = elapsed + maxf(plant.sun_ready, 0.001)

func _activate_sun_network(plant: Dictionary) -> void:
	if not _produce_manual_sun(plant, 1.0): return
	var duration: float = Rules.SUN_WINDOWS[int(plant.rank) - 1]
	_start_sun_window(plant, duration, 1.0)
	for neighbor in sunflower_neighbors(plant):
		_produce_manual_sun(neighbor, Rules.NEIGHBOR_EFFICIENCY)
		_start_sun_window(neighbor, duration, Rules.NEIGHBOR_EFFICIENCY)

func _update_feedback(delta: float) -> void:
	for plant in plants:
		if not control.can_control(plant) or not plant.has("rank"): continue
		plant.pulse = maxf(0, plant.pulse - delta)
		var fraction: float = clampf(plant.charge / Rules.charge_time(plant), 0, 1)
		var scale_value: float = 1 + Rules.FEEDBACK_SCALE * maxf(fraction, plant.pulse / 0.18)
		plant.art.scale = Vector2.ONE * scale_value
		plant.art.position = plant.base_position + Rules.ROOT_PIVOT * (1 - scale_value)
		plant.rank_badge.text = "★".repeat(plant.rank)
	if not is_instance_valid(charge_bar): return
	charge_bar.visible = control.fire_held and not control.selected_plant.is_empty() and not paused and result.is_empty()
	if charge_bar.visible:
		var plant: Dictionary = control.selected_plant
		charge_bar.position = cell_center(plant.cell) + Vector2(-30, -67)
		charge_bar.position.y = maxf(86, charge_bar.position.y)
		charge_bar.value = clampf(plant.charge / Rules.charge_time(plant) * 100, 0, 100)

func _remove_entity(collection: Array[Dictionary], entity: Dictionary) -> void:
	if entity.has("rank_badge"): entity.rank_badge.queue_free()
	super._remove_entity(collection, entity)
	control.validate(plants)
	for row in ROWS:
		var members := pea_members(row)
		row_rounds[row] = 0 if members.is_empty() else mini(row_rounds[row], Rules.chain_rounds(members.size()) - 1)

func toggle_control_mode() -> void:
	if paused or not result.is_empty(): return
	control.enabled = not control.enabled
	control.clear()
	row_rounds.fill(0)
	for plant in plants:
		if plant.has("auto_until"):
			plant.auto_until = 0.0
			plant.full_until = 0.0
			plant.linked_until = 0.0
	_update_feedback(0)
	_update_hud()

func toggle_pause() -> void:
	release_controlled_action()
	super.toggle_pause()
	_update_hud()

func _finish(title: String, message: String) -> void:
	control.clear()
	_update_feedback(0)
	super._finish(title, message)
	_update_hud()

func _update_hud() -> void:
	super._update_hud()
	if not is_instance_valid(control_label): return
	control.validate(plants)
	mode_button.disabled = paused or not result.is_empty()
	mode_button.text = "切换自动" if control.enabled else "切换手动"
	if not control.enabled:
		control_label.text = "自动对照模式\n植物自行执行任务"
	elif control.selected_plant.is_empty():
		control_label.text = "手动模式\n长按豌豆 / 向日葵\n同种叠加升军衔"
	else:
		var plant: Dictionary = control.selected_plant
		var status := "长按充能 %d%%" % roundi(plant.charge / Rules.charge_time(plant) * 100)
		var detail := ""
		if plant.kind == "peashooter":
			if plant.windup >= 0: status = "正在发射"
			var count := pea_members(plant.cell.y).size()
			detail = "同行联动 %d/%d" % [row_rounds[plant.cell.y], Rules.chain_rounds(count)] if count > 1 else "种植同行射手可联动"
		else:
			if plant.sun_ready > 0: status = "产出间隔 %.1f 秒" % plant.sun_ready
			detail = "自动补给 %.1f 秒" % maxf(0, plant.auto_until - elapsed) if plant.auto_until > elapsed else "周围 %d 株 · 75%%产量" % sunflower_neighbors(plant).size()
		control_label.text = "%s · %s\n%s\n%s" % [DEFINITIONS[plant.kind].name, Rules.RANK_NAMES[int(plant.rank) - 1], status, detail]
	if result.is_empty():
		hint_label.text = "已暂停 · 空格继续" if paused else ("左键长按 · 同种叠加升阶 · Tab/F辅助 · 空格暂停" if control.enabled else "自动对照 · 1/2/3选卡 · 4铲子 · 空格暂停")
	control_marker.visible = control.enabled and not control.selected_plant.is_empty() and not paused and result.is_empty()
	if control_marker.visible:
		control_marker.position = GRID_ORIGIN + Vector2(control.selected_plant.cell) * CELL_SIZE
		var plant: Dictionary = control.selected_plant
		if plant.rank < Rules.MAX_RANK:
			seed_buttons[plant.kind].tooltip_text = "%s：同格再种可升至%s，消耗%d阳光" % [DEFINITIONS[plant.kind].name, Rules.RANK_NAMES[int(plant.rank)], DEFINITIONS[plant.kind].cost]
		else: seed_buttons[plant.kind].tooltip_text = "%s已满阶；可在空格种植扩大连锁" % DEFINITIONS[plant.kind].name
