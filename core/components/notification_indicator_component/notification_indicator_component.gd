extends Control
class_name NotificationIndicatorComponent

var _item_id: String = ""

func _ready() -> void:
	# Hide the badge by default
	#hide() 
	pass

# --- PUBLIC API ---
func configure(id: String, _target_override: Control = null) -> void:
	_item_id = id
	_check_status()

func mark_as_seen() -> void:
	if _item_id == "": return
	
	if ProgressionManager.is_item_new(_item_id):
		# It will now ONLY print at the exact millisecond the badge is destroyed!
		#print("💥 BADGE PERMANENTLY CLEARED FOR: ", _item_id) 
		ProgressionManager.mark_item_as_seen(_item_id)
	
	hide()

# --- INTERNAL LOGIC ---
func _check_status() -> void:
	if _item_id == "":
		#print("🔴 Indicator HIDING: _item_id is empty! The component wasn't configured properly.")
		hide()
		return

	if not ProgressionManager.is_item_new(_item_id):
		#print("🔴 Indicator HIDING: ProgressionManager says we already saw item -> ", _item_id)
		hide()
		return

	# If it survives the checks above, it SHOULD be visible!
	#print("🟢 Indicator SHOWN and BLINKING for -> ", _item_id)
	show() 
