extends Control
class_name GameController

# --- DATA ---
@export var intro_conversation: DialogueSequence

func _ready() -> void:
	# Debug: Starter Money
	if Bank.get_currency_amount(GameEnums.CurrencyType.MONEY) == 0:
		Bank.add_currency(GameEnums.CurrencyType.MONEY, 100)
		
	# Start Intro (Optional)
	# if intro_conversation:
	# 	DialogueManager.instance.start_conversation(intro_conversation)

func _on_save_pressed() -> void:
	SaveSystem.save_game()

func _on_load_pressed() -> void:
	SaveSystem.load_game()
