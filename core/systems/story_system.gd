extends Node

# Flag to ensure we only trigger this ONCE per session
var has_triggered_burnout: bool = false

func _ready():
	# Listen to the VitalManager
	if VitalManager:
		VitalManager.vital_depleted.connect(_on_vital_depleted)

func _on_vital_depleted(type: int):
	# We only care about FOCUS (ID: 103 based on your Enums, but 'type' works)
	if type == GameEnums.VitalType.FOCUS:
		_trigger_burnout_event()

func _trigger_burnout_event():
	# 1. Check if already happened (Persistent Check)
	if GameStats.has_flag("unlocked_meditation"):
		return
		
	if has_triggered_burnout: 
		return

	has_triggered_burnout = true
	
	# 2. TRIGGER THE DIALOGUE
	var lines = [
		"Unknown: ...Why are you running so fast?",
		"Unknown: You are exhausting yourself for numbers on a screen.",
		"Unknown: Check the shop. I've left something for you."
	]
	print("DIALOGUE TRIGGERED: ", lines)
	SignalBus.message_logged.emit("You feel a sudden clarity...", Color.VIOLET)
	
	# 3. CRITICAL FIX: Set the Flag!
	GameStats.set_flag("unlocked_meditation", true)
	
	# 4. Force Shop Refresh
	# We emit a "fake" upgrade event so the ShopPanel re-runs its _populate_shop() function
	UpgradeManager.upgrade_leveled_up.emit("story_event", 0)
