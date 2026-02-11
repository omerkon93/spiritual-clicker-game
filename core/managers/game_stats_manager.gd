extends Node

# Persistent flags (e.g. "met_wizard", "unlocked_meditation")
var _story_flags: Dictionary = {}

func set_flag(flag_name: String, value: bool = true) -> void:
	_story_flags[flag_name] = value
	# Optional: You could trigger a save here later

func has_flag(flag_name: String) -> bool:
	return _story_flags.get(flag_name, false)

# Calculates total power based on upgrades
func get_stat_value(stat_def: StatDefinition, contributing_upgrades: Array[LevelableUpgrade]) -> float:
	var total = stat_def.base_value
	
	for upgrade in contributing_upgrades:
		if upgrade == null: continue
		
		var level = UpgradeManager.get_upgrade_level(upgrade.id)
		if level > 0:
			total += (level * upgrade.power_per_level)
			
	return total

# --- SAVE / LOAD ---
func get_save_data() -> Dictionary:
	# Duplicate ensures we don't accidentally modify the live data while saving
	return _story_flags.duplicate()

func load_save_data(data: Dictionary) -> void:
	_story_flags = data
	
	# Optional: If you have a signal for flags changing, emit it here
	# flags_updated.emit()
