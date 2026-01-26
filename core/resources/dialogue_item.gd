extends Resource
class_name DialogueItem

@export var speaker_name: String = "Shopkeeper"
@export_multiline var text: String = "Welcome!"
@export var portrait: Texture2D

# NEW: The list of buttons to show
@export var options: Array[DialogueOption]
