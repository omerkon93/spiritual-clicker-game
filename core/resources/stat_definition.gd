class_name StatDefinition extends Resource

enum StatType {
	NONE= 200,
	CLICK_POWER,
	CLICK_COOLDOWN,
	AUTO_PRODUCTION,
	CRIT_CHANCE
}

# Now uses the dropdown from StatDefinition.StatType
@export var stat_type: StatType = StatType.NONE
@export var display_name: String = "Stat Name"
@export var base_value: float = 1.0
