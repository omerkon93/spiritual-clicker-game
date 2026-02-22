class_name StatDefinition extends Resource

enum StatType {
	NONE= 200,
	## Actions gain more Money/Vital
	ACTION_POWER,
	## Actions cost less time
	ACTION_TIME_EFFICIENCY,
	## Actions cost less energy
	ACTION_ENERGY_EFFICIENCY,
	## Faster research speed
	RESEARCH_SPEED,
	## Boosts scripting efficiency
	AUTOMATION_EFFICIENCY
}

# Now uses the dropdown from StatDefinition.StatType
@export var stat_type: StatType = StatType.NONE
@export var display_name: String = "Stat Name"
@export var base_value: float = 1.0
