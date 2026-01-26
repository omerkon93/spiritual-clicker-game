extends Node

# Load the scene we just created
@export var floating_text_scene: PackedScene = preload("res://scenes/ui/effects/floating_text.tscn")
@export var particle_scene: PackedScene = preload("res://scenes/ui/effects/click_particles.tscn")

# We create a dedicated rendering layer for effects
var _canvas_layer: CanvasLayer

func _ready():
	SignalBus.request_floating_text.connect(_spawn_text)
	SignalBus.request_floating_text.connect(_on_text_requested)
	
	# Create the layer dynamically
	_canvas_layer = CanvasLayer.new()
	# Layer 1 is standard UI. Layer 100 ensures this is ABOVE everything.
	_canvas_layer.layer = 100 
	add_child(_canvas_layer)

func _spawn_text(pos: Vector2, text: String, color: Color):
	if not floating_text_scene: return
	
	var instance = floating_text_scene.instantiate()
	
	# Add the text to our special Top Layer instead of the scene tree
	_canvas_layer.add_child(instance)
	
	# Start the animation
	if instance.has_method("animate"):
		instance.animate(pos, text, color)

func _on_text_requested(pos, text, color):
	# 1. Spawn Text (Existing)
	_spawn_text(pos, text, color)

	# 2. Spawn Particles (NEW)
	if particle_scene:
		var p = particle_scene.instantiate()
		p.global_position = pos
		add_child(p)
