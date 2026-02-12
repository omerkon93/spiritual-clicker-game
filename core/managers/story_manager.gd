extends Node

var has_triggered_burnout: bool = false

func _ready():
	if VitalManager:
		VitalManager.vital_depleted.connect(_on_vital_depleted)

func _on_vital_depleted(type: int):
	if type == GameEnums.VitalType.FOCUS:
		_trigger_burnout_event()

func _trigger_burnout_event():
	# REFACTOR: Use ProgressionManager for flag checks
	if ProgressionManager.get_flag("unlocked_meditation"):
		return
		
	if has_triggered_burnout: 
		return

	has_triggered_burnout = true
	
	@warning_ignore("unused_variable")
	var lines = [
		"Unknown: ...Why are you running so fast?",
		"Unknown: You are exhausting yourself for numbers on a screen.",
		"Unknown: Check the shop. I've left something for you."
	]
	SignalBus.message_logged.emit("You feel a sudden clarity...", Color.VIOLET)
	
	# REFACTOR: Set flag via ProgressionManager
	ProgressionManager.set_flag("unlocked_meditation", true)
	
	# Force Shop Refresh
	# We still use the signal, but it comes from ProgressionManager now
	ProgressionManager.upgrade_leveled_up.emit("story_event", 0)
