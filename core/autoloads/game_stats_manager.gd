extends Node

func set_flag(flag_name: String, value: bool = true) -> void:
	ProgressionManager.set_flag(flag_name, value)

func has_flag(flag_name: String) -> bool:
	return ProgressionManager.get_flag(flag_name)

# Calculates total stat value dynamically by reading item effects
func get_stat_value(stat_def: StatDefinition, contributing_items: Array[GameItem]) -> float:
	var flat_total = stat_def.base_value
	var percentage_bonus = 0.0
	
	for item in contributing_items:
		if item == null: continue
		
		var level = ProgressionManager.get_upgrade_level(item.id)
		if level > 0:
			# Look through the effects array instead of blindly using power_per_level
			for effect in item.effects:
				if effect != null and "stat" in effect and "amount" in effect:
					# Check if this effect matches the stat we are calculating
					if effect.stat == stat_def.stat_type:
						if "is_percentage" in effect and effect.is_percentage:
							# Add to the multiplier (e.g., 0.10 means +10%)
							percentage_bonus += (effect.amount * level)
						else:
							# Add to the flat base value
							flat_total += (effect.amount * level)
						
	# Return the final math: (Base + Flat Bonuses) * (100% + Percentage Bonuses)
	return flat_total * (1.0 + percentage_bonus)
