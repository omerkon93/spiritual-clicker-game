extends CanvasLayer
class_name FloatingTextComponent

# Use PackedScene so we can spawn new copies of the text
@export var floating_text_scene: PackedScene

func _ready() -> void:
	# Set the Z-Index high so it appears above all other UI/Windows
	layer = 100
	
	# Connect to SignalBus
	SignalBus.request_floating_text.connect(_on_floating_text_requested)

# Arguments match SignalBus: (Position, Text, Color)
func _on_floating_text_requested(pos: Vector2, text: String, color: Color) -> void:
	if not floating_text_scene: return
	
	# Create a new instance of the text
	var txt = floating_text_scene.instantiate()
	
	# Add it directly to THIS node (which is now a CanvasLayer)
	add_child(txt)
	
	# Trigger the animation
	if txt.has_method("animate"):
		txt.animate(pos, text, color)
