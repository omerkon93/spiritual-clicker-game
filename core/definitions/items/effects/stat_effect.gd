extends ItemEffect
class_name StatEffect

@export var stat: StatDefinition.StatType = StatDefinition.StatType.NONE
@export var amount: float = 1.0

## If true, 'amount' of 0.1 means +10%.
## If false, 'amount' of 10 means +10 Flat.
@export var is_percentage: bool = false 

func apply() -> void:
	# Note: If you use GameStatsManager, you'll need to update it to support 
	# percentage too. For now, we are focusing on ActionData.
	if GameStatsManager.has_method("modify_stat"):
		GameStatsManager.modify_stat(stat, amount)
