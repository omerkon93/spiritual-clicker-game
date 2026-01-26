extends Node

# Signals
signal vital_changed(type: GameEnums.VitalType, current: float, max_val: float)
signal vital_depleted(type: GameEnums.VitalType) # E.g. You passed out!

# Data Storage
# format: { VitalType: { "current": 50.0, "max": 100.0 } }
var vitals: Dictionary = {}

func _ready():
	# Initialize default vitals
	_init_vital(GameEnums.VitalType.SANITY, 100.0)
	_init_vital(GameEnums.VitalType.ENERGY, 100.0)
	_init_vital(GameEnums.VitalType.HUNGER, 100.0)

func _init_vital(type: int, default_max: float):
	vitals[type] = {
		"current": default_max,
		"max": default_max
	}

# --- PUBLIC API ---

func get_current(type: int) -> float:
	if type in vitals:
		return vitals[type]["current"]
	return 0.0

func has_enough(type: int, amount: float) -> bool:
	return get_current(type) >= amount

func change_vital(type: int, amount: float):
	if not type in vitals: return
	
	var data = vitals[type]
	
	# Apply change (add or subtract)
	data["current"] += amount
	
	# Clamp logic (Cannot go below 0 or above Max)
	data["current"] = clamp(data["current"], 0, data["max"])
	
	# Emit updates
	vital_changed.emit(type, data["current"], data["max"])
	
	if data["current"] == 0:
		vital_depleted.emit(type)

# Add this function so the label can read the max value
func get_max(type: int) -> float:
	if type in vitals:
		return vitals[type]["max"]
	return 0.0 # Return 0 if not found (Label will handle the fallback)

# Shortcut for "Spending" sanity
func consume(type: int, amount: float) -> bool:
	if has_enough(type, amount):
		change_vital(type, -amount)
		return true
	return false

# Shortcut for "Healing"
func restore(type: int, amount: float):
	change_vital(type, amount)
