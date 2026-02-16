extends Control
class_name NotificationIndicatorComponent

# --- CONFIGURATION ---
# The node that should blink. If null, it defaults to the parent (the Button).
@export var blink_target: Control 

var _item_id: String = ""
var _blink_tween: Tween

func _ready() -> void:
	# Hide the red dot/icon by default
	hide() 

# --- PUBLIC API ---

# Call this to set up tracking for a specific item ID
func configure(id: String, target_override: Control = null) -> void:
	_item_id = id
	
	# Determine what should blink
	if target_override:
		blink_target = target_override
	elif not blink_target and get_parent() is Control:
		blink_target = get_parent()

	_check_status()

# Call this when the item is clicked
func mark_as_seen() -> void:
	if _item_id == "": return
	
	# 1. Update Data
	if ProgressionManager.is_item_new(_item_id):
		ProgressionManager.mark_item_as_seen(_item_id)
	
	# 2. Update Visuals immediately (Stop blink, hide dot)
	_stop_blinking()
	hide() 

# --- INTERNAL LOGIC ---

func _check_status() -> void:
	# If invalid ID or already seen, clean up and hide
	if _item_id == "" or not ProgressionManager.is_item_new(_item_id):
		_stop_blinking()
		hide()
		return

	# If New: Show Dot and Start Blinking
	show() 
	_start_blinking()

func _start_blinking() -> void:
	if not blink_target: return
	
	# Don't restart if already running
	if _blink_tween and _blink_tween.is_valid(): return
	
	# Reset color first
	blink_target.self_modulate = Color.WHITE
	
	_blink_tween = create_tween().set_loops()
	
	# BRIGHTNESS LEVEL: NUCLEAR (Pulse to bright Gold and back)
	_blink_tween.tween_property(blink_target, "self_modulate", Color(4.0, 3.5, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	_blink_tween.tween_property(blink_target, "self_modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)

func _stop_blinking() -> void:
	if _blink_tween: _blink_tween.kill()
	
	if blink_target:
		blink_target.self_modulate = Color.WHITE
