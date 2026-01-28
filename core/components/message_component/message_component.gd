extends Node
class_name MessageComponent

# --- DATA ---
# Not exported! This is injected by the ActionButton at runtime.
var failure_messages: Dictionary[int, String] = {}

# Fallback in case the Resource didn't provide a specific message
var default_message: String = "Not enough resources."

# --- PUBLIC API ---

# Connect this to cost_component.check_failed
func on_check_failed(reason_type: int) -> void:
	var msg: String = failure_messages.get(reason_type, default_message)
	
	# DYNAMIC COLOR FETCHING
	# No more hardcoded "if money == gold" checks!
	var color: Color = ResourceConfig.get_color(reason_type)
	
	# Fallback: If color is white (maybe default), make it red for error visibility
	if color == Color.WHITE:
		color = Color.RED
		
	SignalBus.message_logged.emit(msg, color)
