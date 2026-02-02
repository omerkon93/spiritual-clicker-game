extends Button

# LINK: Drag the DialogueComponent (child node) here!
@export var dialogue_component: DialogueComponent

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if dialogue_component:
		# The Component knows which conversation to play
		dialogue_component.start_dialogue()
	else:
		printerr("ShopTrigger: No DialogueComponent assigned!")
