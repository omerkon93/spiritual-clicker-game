extends Node

# Signals
signal vital_changed(type: GameEnums.VitalType, current: float, max_val: float)
signal vital_depleted(type: GameEnums.VitalType) # E.g. You passed out!

# Data Storage
# format: { VitalType: { "current": 50.0, "max": 100.0 } }
var vitals: Dictionary = {}

func _ready():
	# Initialize default vitals
	_init_vital(GameEnums.VitalType.ENERGY, 100.0)
	_init_vital(GameEnums.VitalType.FULLNESS, 100.0)
	_init_vital(GameEnums.VitalType.FOCUS, 100.0)
	_init_vital(GameEnums.VitalType.SANITY, 100.0)

func _init_vital(type: int, default_max: float):
	vitals[type] = {
		"current": default_max,
		"max": default_max
	}

# --- PUBLIC API ---

func get_current(type: int) -> float:
	return vitals.get(type, {}).get("current", 0.0)

func get_max(type: int) -> float:
	return vitals.get(type, {}).get("max", 100.0)

func has_enough(type: int, amount: float) -> bool:
	return get_current(type) >= amount

func change_vital(type: int, amount: float):
	if not type in vitals: return
	var data = vitals[type]
	
	data["current"] = clamp(data["current"] + amount, 0, data["max"])
	vital_changed.emit(type, data["current"], data["max"])
	
	if data["current"] == 0 and amount < 0:
		vital_depleted.emit(type)

func consume(type: int, amount: float) -> bool:
	if has_enough(type, amount):
		change_vital(type, -amount)
		return true
	return false

func restore(type: int, amount: float):
	change_vital(type, amount)
