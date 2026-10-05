extends RefCounted
## Prototype tuning kept separate from input, combat and presentation.
const MAX_RANK := 3
const RANK_NAMES := ["新兵", "士官", "精英"]
const PEA_CHARGE := [0.95, 0.80, 0.65]
const PEA_DAMAGE := [20, 24, 28]
const SUN_CHARGE := 2.4
const SUN_WINDOWS := [24.0, 40.0, 60.0]
const SUN_INTERVAL := 8.0
const SUN_VALUES := [25, 30, 35]
const SUN_STOP := "stop"
const SUN_WORK := "work"
const SUN_WEAK_WORK := "weak_work"
# Six integer units represent one full row volley; no floating-point drift.
const ROW_THRESHOLD := 6
const ROW_CONTRIBUTIONS := [2, 3, 6]
const NEIGHBOR_EFFICIENCY := 0.75
const FEEDBACK_SCALE := 0.12
const ROOT_PIVOT := Vector2(40, 64)

static func charge_time(plant: Dictionary) -> float:
	return PEA_CHARGE[int(plant.rank) - 1] if plant.kind == "peashooter" else SUN_CHARGE

static func chain_rounds(rank: int) -> int:
	return [3, 2, 1][rank - 1]
