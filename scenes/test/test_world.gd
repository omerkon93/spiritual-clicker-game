extends Control
@export var intro : Conversation

@onready var tech_panel: ShopPanel = $HBoxContainer/VBoxContainer/MarginContainer3/TechPanel
@onready var shop_panel: ShopPanel = $HBoxContainer/VBoxContainer/MarginContainer2/ShopPanel

var money : GameEnums.CurrencyType = GameEnums.CurrencyType.MONEY

func _ready() -> void:
	if Bank.get_currency_amount(money) == 0:
		Bank.add_currency(money, 100)
	
	SignalBus.message_logged.emit("Welcome, Miner! Click to start earning.", Color.GREEN)
	SignalBus.dialogue_action.connect(_on_dialogue_action)
	shop_panel.visible = true
	tech_panel.visible = false
	# Load the resource (adjust path to where you saved it)

	# Wait 1 second then talk
	#await get_tree().create_timer(1.0).timeout
	#DialogueManager.instance.start_conversation(intro)

func _on_save_pressed() -> void:
	SaveSystem.save_game()

func _on_load_pressed() -> void:
	SaveSystem.load_game()

func _on_dialogue_action(action_id: String):
	match action_id:
		"open_shop":
			shop_panel.visible = true
			SignalBus.message_logged.emit("Shop opened.", Color.GREEN)
		"close_shop":
			shop_panel.visible = false
			SignalBus.message_logged.emit("Shop closed.", Color.GREEN)
		"give_money":
			Bank.add_currency(money, 100)
			SignalBus.message_logged.emit("Shopkeeper gave you a gift!", Color.YELLOW)
