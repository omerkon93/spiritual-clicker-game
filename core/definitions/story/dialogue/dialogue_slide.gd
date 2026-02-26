extends Resource
class_name DialogueSlide

@export_group("Content")
@export var speaker_name: String = "Shopkeeper"
@export_multiline var text: String = "Welcome! How can I help?"
@export var portrait: Texture2D

@export_group("Choices")
# CHANGED: We now use an Array of our new custom resources
@export var options: Array[DialogueOption] = []
