extends Resource
class_name DialogueSlide

@export_group("Content")
@export var speaker_name: String = "Shopkeeper"
@export_multiline var text: String = "Welcome! How can I help?"
@export var portrait: Texture2D

@export_group("Choices")
# KEY = Button Text
# VALUE = Resource (Accepts DialogueTrigger OR DialogueSequence)
# We must use 'Resource' here to allow different types!
@export var options: Dictionary[String, Resource] = {}
