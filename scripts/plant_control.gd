extends RefCounted
## Player selection/input ownership. Attack timing and effects remain in gameplay.
## Later plants can expose different actions without requiring every plant to be manual.

var enabled := true
var fire_held := false
var selected_plant: Dictionary = {}

func can_control(plant: Dictionary) -> bool:
	return plant.get("kind", "") == "peashooter"

func requires_input(plant: Dictionary) -> bool:
	return enabled and can_control(plant)

func select(plant: Dictionary, living_plants: Array) -> bool:
	if not enabled or not living_plants.has(plant) or not can_control(plant): return false
	selected_plant = plant
	return true

func clear() -> void:
	selected_plant = {}
	fire_held = false

func validate(living_plants: Array) -> void:
	if not selected_plant.is_empty() and not living_plants.has(selected_plant): clear()

func cycle(living_plants: Array) -> bool:
	if not enabled: return false
	var candidates: Array[Dictionary] = []
	for plant in living_plants:
		if can_control(plant): candidates.append(plant)
	if candidates.is_empty():
		clear()
		return false
	var index := candidates.find(selected_plant)
	selected_plant = candidates[(index + 1) % candidates.size()]
	return true
