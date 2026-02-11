extends Node
class_name ShopWindowComponent

# --- DEPENDENCIES ---
# Assign these in Inspector
@export var shop_panel: ShopMenu
@export var tech_panel: ShopMenu

# --- SETUP ---
func _ready() -> void:
	SignalBus.dialogue_action.connect(_on_dialogue_action)
	
	# Start with both closed (Safety check)
	_close_all()

# --- LOGIC ---
func _on_dialogue_action(action_id: String) -> void:
	match action_id:
		"open_shop":
			_open_panel(shop_panel)
			SignalBus.message_logged.emit("General Store opened.", Color.GREEN)
			
		"open_tech":
			_open_panel(tech_panel)
			SignalBus.message_logged.emit("Tech Lab accessed.", Color.CYAN)
			
		"close_shops":
			_close_all()
			SignalBus.message_logged.emit("Leaving shop...", Color.WHITE)

# --- HELPERS ---
func _open_panel(target: ShopMenu) -> void:
	# Enforce "One at a time" rule
	_close_all()
	
	if target:
		target.open()

func _close_all() -> void:
	if shop_panel: shop_panel.close()
	if tech_panel: tech_panel.close()
