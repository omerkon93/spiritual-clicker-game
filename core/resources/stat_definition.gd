class_name StatDefinition extends Resource

enum StatType {
	NONE= 200,
	## Basic Money/Vital gain boost
	CLICK_POWER,
	## Faster button resets
	CLICK_COOLDOWN,
	## Reduces time spent (Refurbished Server)
	STUDY_EFFICIENCY,
	## Boosts scripting rewards (IDE)
	AUTOMATION_EFFICIENCY
}

# Now uses the dropdown from StatDefinition.StatType
@export var stat_type: StatType = StatType.NONE
@export var display_name: String = "Stat Name"
@export var base_value: float = 1.0
