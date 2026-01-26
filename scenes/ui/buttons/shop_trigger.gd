extends Button

# Drag "Shopkeeper_Intro.tres" here in the Inspector!
@export var conversation_to_start: Conversation

func _ready():
	# Connect our OWN pressed signal to our OWN function
	pressed.connect(_on_pressed)

func _on_pressed():
	if conversation_to_start:
		DialogueManager.instance.start_conversation(conversation_to_start)
	else:
		printerr("ShopTrigger: No conversation assigned!")
