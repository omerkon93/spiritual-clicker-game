extends Node

# Signals to update UI
signal upgrade_leveled_up(id: String, new_level: int)
signal flag_changed(flag: String, value: bool)

# ==============================================================================
# STATE (SAVED DATA)
# ==============================================================================
# Mapping: "upgrade_id" -> level (int)
var upgrade_levels: Dictionary = {}

# Mapping: "flag_name" -> is_active (bool)
var story_flags: Dictionary = {}

# ==============================================================================
# PUBLIC API: UPGRADES
# ==============================================================================
func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)

func increment_upgrade_level(id: String, amount: int = 1) -> void:
	var current = get_upgrade_level(id)
	var new_level = current + amount
	upgrade_levels[id] = new_level
	upgrade_leveled_up.emit(id, new_level)

# ==============================================================================
# PUBLIC API: STORY FLAGS
# ==============================================================================
func get_flag(flag: String) -> bool:
	return story_flags.get(flag, false)

func set_flag(flag: String, value: bool = true) -> void:
	if story_flags.get(flag) != value:
		story_flags[flag] = value
		flag_changed.emit(flag, value)

# ==============================================================================
# PERSISTENCE
# ==============================================================================
func get_save_data() -> Dictionary:
	return {
		"upgrades": upgrade_levels.duplicate(),
		"flags": story_flags.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("upgrades"):
		upgrade_levels = data["upgrades"]
	
	if data.has("flags"):
		story_flags = data["flags"]
	
	# Re-emit signals to update UI components after load
	for id in upgrade_levels:
		upgrade_leveled_up.emit(id, upgrade_levels[id])
	for flag in story_flags:
		flag_changed.emit(flag, story_flags[flag])
