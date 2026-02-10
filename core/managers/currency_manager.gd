extends Node

# Dictionary mapping [GameEnums.CurrencyType] -> [float Amount]
var _wallet: Dictionary = {}

# Signal sends the Enum type and the new amount
signal currency_changed(type: GameEnums.CurrencyType, new_amount: float)

func initialize_currencies(currencies: Array[CurrencyDefinition]):
	for c in currencies:
		# Use the Enum as the key
		if not _wallet.has(c.type):
			_wallet[c.type] = c.initial_amount

func add_currency(type: GameEnums.CurrencyType, amount: float):
	if not _wallet.has(type): 
		_wallet[type] = 0.0
	
	_wallet[type] += amount
	currency_changed.emit(type, _wallet[type])

func has_enough_currency(type: GameEnums.CurrencyType, amount: float) -> bool:
	return _wallet.get(type, 0.0) >= amount

func spend_currency(type: GameEnums.CurrencyType, amount: float):
	if has_enough_currency(type, amount):
		_wallet[type] -= amount
		currency_changed.emit(type, _wallet[type])

func get_currency_amount(type: GameEnums.CurrencyType) -> float:
	return _wallet.get(type, 0.0)

# Added this Helper for the SaveManager to use when loading data
func set_currency(type: GameEnums.CurrencyType, amount: float):
	_wallet[type] = amount
	currency_changed.emit(type, amount)
