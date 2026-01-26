extends Resource
class_name DialogueOption

@export var text: String = "Enter Shop"
# If set, clicking this leads to another conversation (Branching)
@export var next_conversation: Conversation 
# If set, we emit this event ID so the Game World can react (e.g. "open_shop")
@export var action_id: String = ""
# If true, the dialogue box closes immediately after clicking
@export var close_dialogue: bool = true
