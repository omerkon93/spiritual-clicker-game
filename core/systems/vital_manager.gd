extends Node

# Signals
signal vital_changed(type: GameEnums.VitalType, current: float, max_val: float)
signal vital_depleted(type: GameEnums.VitalType) 

# Data Storage
# format: { VitalType: { "current": 50.0, "max": 100.0 } }
var vitals: Dictionary = {}

func _ready() -> void:
	# Initialize default vitals
	_init_vital(GameEnums.VitalType.ENERGY, 100.0)
	_init_vital(GameEnums.VitalType.FULLNESS, 100.0)
	_init_vital(GameEnums.VitalType.FOCUS, 100.0)
	_init_vital(GameEnums.VitalType.SANITY, 100.0)

func _init_vital(type: int, default_max: float) -> void:
	vitals[type] = {
		"current": default_max,
		"max": default_max
	}

# --- PUBLIC API ---

func get_current(type: int) -> float:
	if not type in vitals: return 0.0
	return vitals[type]["current"]

func get_max(type: int) -> float:
	if not type in vitals: return 100.0
	return vitals[type]["max"]

func has_enough(type: int, amount: float) -> bool:
	return get_current(type) >= amount

func change_vital(type: int, amount: float) -> void:
	if not type in vitals: return
	
	var data = vitals[type]
	var old_value: float = data["current"]
	
	# Apply change and clamp
	data["current"] = clampf(data["current"] + amount, 0.0, data["max"])
	var new_value: float = data["current"]
	
	# Emit update signal only if changed
	if old_value != new_value:
		vital_changed.emit(type, new_value, data["max"])
	
	# Emit depletion signal ONLY if we just hit 0 (Transition)
	if new_value <= 0.0 and old_value > 0.0:
		vital_depleted.emit(type)

func consume(type: int, amount: float) -> bool:
	if has_enough(type, amount):
		change_vital(type, -amount)
		return true
	return false

func restore(type: int, amount: float) -> void:
	change_vital(type, amount)
