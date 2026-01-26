extends Control

# Drag "Gold.tres" here in the Inspector
@export var monitored_currency: CurrencyDefinition

@onready var currency_icon: TextureRect = $HBoxContainer/CurrencyIcon
@onready var label: Label = $HBoxContainer/Label

func _ready():
	if not monitored_currency:
		printerr("CurrencyLabel Error: No CurrencyDefinition assigned!")
		return

	# 1. Connect to signal
	Bank.currency_changed.connect(_on_currency_changed)
	
	# 2. Get Initial Amount (SAFER WAY)
	# Use the public function instead of accessing the private dictionary directly
	var current_amount = Bank.get_currency(monitored_currency.type)
	_update_text(current_amount)
	
	# 3. Set Icon
	if currency_icon and monitored_currency.icon:
		currency_icon.texture = monitored_currency.icon

func _on_currency_changed(type: GameEnums.CurrencyType, new_amount: float):
	# Check if the signal matches our target Enum
	if type == monitored_currency.type:
		_update_text(new_amount)

func _update_text(amount: float):
	var formatted_amount = NumberFormatter.format_value(amount)
	label.text = "%s: %s" % [monitored_currency.display_name, formatted_amount]
