extends Control
class_name CurrenciesLabel

# Drag "Gold.tres" here in the Inspector
@export var monitored_currency: CurrencyDefinition

@onready var currency_icon: TextureRect = $HBoxContainer/CurrencyIcon
@onready var currency_label: Label = $HBoxContainer/CurrencyLabel

func _ready():
	if not monitored_currency:
		printerr("CurrencyLabel Error: No CurrencyDefinition assigned!")
		return

	# 1. Connect to signal
	Bank.currency_changed.connect(_on_currency_changed)
	
	# 2. Get Initial Amount (SAFER WAY)
	# Use the public function instead of accessing the private dictionary directly
	var current_amount = Bank.get_currency_amount(monitored_currency.type)
	_update_text(current_amount)
	_check_visibility()
	
	# 3. Set Icon
	if currency_icon and monitored_currency.icon:
		currency_icon.texture = monitored_currency.icon

func _on_currency_changed(type: GameEnums.CurrencyType, new_amount: float):
	if type == monitored_currency.type:
		_update_text(new_amount)
		# If we suddenly gain this currency, reveal the UI!
		if new_amount > 0 and not visible:
			show()
			# Optional: Play a "Discovery" sound or animation here

func _update_text(amount: float):
	var formatted_amount = NumberFormatter.format_value(amount)
	currency_label.text = "%s: %s" % [monitored_currency.display_name, formatted_amount]

func _check_visibility():
	# If it's MONEY, always show it.
	if monitored_currency.type == GameEnums.CurrencyType.MONEY:
		show()
		return

	# For SPIRIT or others, only show if we actually HAVE some (or have unlocked it)
	var current_amount = Bank.get_currency_amount(monitored_currency.type)
	if current_amount > 0:
		show()
	else:
		hide()
