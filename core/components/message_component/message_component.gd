extends Node
class_name MessageComponent

# Defines specific messages for specific failures (Optional)
# Key: The text to match (e.g. "Not enough Energy!"), Value: Custom override
@export var failure_messages: Dictionary = {}

func on_check_failed(reason: String) -> void:
	# 1. Check if we have a custom override for this specific string
	# (Rarely used now since CostComponent generates good text, but good to have)
	var final_message: String = reason
	if failure_messages.has(reason):
		final_message = failure_messages[reason]
	
	# 2. Display the Feedback
	_spawn_floating_text(final_message, Color.RED)

func _spawn_floating_text(text: String, color: Color) -> void:
	var pos: Vector2 = get_viewport().get_mouse_position()
	
	# Add a little randomness so they don't stack perfectly
	pos.x += randf_range(-10, 10)
	pos.y += randf_range(-10, 10)
	
	# Send to the global event bus
	SignalBus.request_floating_text.emit(pos, text, color)
