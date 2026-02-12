extends Node

# NOTE: removed internal _story_flags variable.

# Forward to ProgressionManager
func set_flag(flag_name: String, value: bool = true) -> void:
	ProgressionManager.set_flag(flag_name, value)

func has_flag(flag_name: String) -> bool:
	return ProgressionManager.get_flag(flag_name)

# Calculates total power based on upgrades
func get_stat_value(stat_def: StatDefinition, contributing_upgrades: Array[LevelableUpgrade]) -> float:
	var total = stat_def.base_value
	
	for upgrade in contributing_upgrades:
		if upgrade == null: continue
		
		# REFACTOR: Check ProgressionManager for level
		var level = ProgressionManager.get_upgrade_level(upgrade.id)
		if level > 0:
			total += (level * upgrade.power_per_level)
			
	return total

# NOTE: Save/Load removed. Logic delegated to ProgressionManager.
