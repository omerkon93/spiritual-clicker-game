extends Node

# Now accepts an Array of upgrades instead of a single one
func get_stat_value(stat_def: StatDefinition, contributing_upgrades: Array[LevelableUpgrade]) -> float:
	var total = stat_def.base_value
	
	# Loop through every upgrade attached to the producer
	for upgrade in contributing_upgrades:
		if upgrade == null: continue
		
		# Look up level using the STRING ID
		var level = UpgradeManager.get_upgrade_level(upgrade.id)
		
		if level > 0:
			total += (level * upgrade.power_per_level)
			
	return total
