extends Resource
class_name StoryFlagRequirement

## The flag required to unlock this item.
@export var required_flag: StoryFlag

## Should the flag be TRUE or FALSE to pass?
@export var required_value: bool = true

func is_met() -> bool:
	if not required_flag: return true
	# Check the actual ID against the ProgressionManager
	return ProgressionManager.get_flag(required_flag.id) == required_value

func get_cost_text() -> String:
	# This usually doesn't show in "Cost", but helps for debugging tooltips
	return ""
