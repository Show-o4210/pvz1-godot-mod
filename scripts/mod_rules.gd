extends RefCounted
## Prototype tuning kept separate from input, combat and presentation.
const MAX_RANK := 3
const RANK_NAMES := ["新兵", "士官", "精英"]
const PEA_CHARGE := [0.95, 0.80, 0.65]
const PEA_DAMAGE := [20, 24, 28]
const SUN_CHARGE := 2.4
const SUN_WINDOWS := [0.0, 6.0, 12.0]
const SUN_INTERVAL := 4.0
const SUN_VALUE := 25
const NEIGHBOR_EFFICIENCY := 0.75
const FEEDBACK_SCALE := 0.12
const ROOT_PIVOT := Vector2(40, 64)

static func charge_time(plant: Dictionary) -> float:
	return PEA_CHARGE[int(plant.rank) - 1] if plant.kind == "peashooter" else SUN_CHARGE

static func chain_rounds(count: int) -> int:
	if count <= 1: return 1
	if count <= 3: return 2
	if count <= 6: return 3
	return 4
