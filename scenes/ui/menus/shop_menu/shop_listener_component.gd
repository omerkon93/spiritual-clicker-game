extends Node
class_name ShopListenerComponent

@export_category("Configuration")
# Which signal ID to listen for (matches your Trigger Resource)
@export var trigger_id: String = "open_shop"

@export_category("References")
# The panel to open when the signal is heard
@export var target_panel: ShopMenu

func _ready() -> void:
	SignalBus.dialogue_action.connect(_on_dialogue_action)

func _on_dialogue_action(signal_id: String) -> void:
	# 1. Filter: Is this the signal we are waiting for?
	if signal_id != trigger_id:
		return
		
	# 2. Action: Open the panel
	if target_panel:
		target_panel.open()
		# Optional: Log it so you know it worked
		print("🛒 Shop Listener: Opening Shop Panel!")
	else:
		printerr("❌ ShopListener: No Target Panel assigned!")
