extends Node

# Flag to ensure we only trigger this ONCE
var has_triggered_burnout: bool = false

func _ready():
	# Listen to the VitalManager
	VitalManager.vital_depleted.connect(_on_vital_depleted)

func _on_vital_depleted(type):
	# We only care about FOCUS (ID: 3)
	if type == GameEnums.VitalType.FOCUS:
		_trigger_burnout_event()

func _trigger_burnout_event():
	if has_triggered_burnout: return
	
	# Check if we already have Spirit (if so, we don't need this event)
	if Bank.get_currency_amount(GameEnums.CurrencyType.SPIRIT) > 0:
		return

	has_triggered_burnout = true
	
	# 1. Send the Dialogue Signal (Connect this to your UI!)
	var lines = [
		"Unknown: ...Why are you running so fast?",
		"Unknown: You are exhausting yourself for numbers on a screen.",
		"Unknown: Check the shop. I've left something for you."
	]
	SignalBus.message_logged.emit("Received a strange message...", Color.VIOLET)
	print("DIALOGUE TRIGGERED: ", lines) # Replace with your DialogueUI.show(lines)
	
	# 2. UNLOCK THE ITEM
	# This sets a "Global Flag" or simply adds the item to the Shop's inventory array
	# Assuming your Shop has a method like 'unlock_item(id)' or you use a global list:
	_unlock_mindfulness_research()

func _unlock_mindfulness_research():
	# Option A: If your shop pulls from a specific folder, you might not need to do anything
	# but set a flag.
	
	# Option B: Add it to the "Available Upgrades" list in UpgradeManager
	var item_path = "res://game_data/upgrades/Research_Mindfulness.tres"
	if ResourceLoader.exists(item_path):
		var item = load(item_path)
		# Add to the global manager so the shop sees it
		UpgradeManager.add_available_upgrade(item)
		SignalBus.message_logged.emit("New Item Available: Mindfulness App", Color.GREEN)
