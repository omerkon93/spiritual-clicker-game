extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================
signal currency_changed(type: GameEnums.CurrencyType, new_amount: float)


# ==============================================================================
# DATA STORAGE
# ==============================================================================
# Dynamic State: Mapping [GameEnums.CurrencyType] -> [float Amount]
var _currencies: Dictionary = {}

# Static Config: Mapping [GameEnums.CurrencyType] -> [CurrencyDefinition]
var _definitions: Dictionary = {} 


# ==============================================================================
# INITIALIZATION
# ==============================================================================
# Called by the Game/Bootstrap to register all available currencies
func initialize_currencies(currencies: Array[CurrencyDefinition]):
	for c in currencies:
		# 1. Store the Definition (for UI lookups later)
		_definitions[c.type] = c
		
		# 2. Initialize the bank account if it doesn't exist
		if not _currencies.has(c.type):
			_currencies[c.type] = c.initial_amount


# ==============================================================================
# PUBLIC API: GETTERS
# ==============================================================================
# Retrieves the static Resource file (for UI Icons/Colors)
func get_definition(type: GameEnums.CurrencyType) -> CurrencyDefinition:
	if _definitions.has(type):
		return _definitions[type]
	
	push_error("Currency Definition not found for type: %s" % type)
	return null

func get_currency_amount(type: GameEnums.CurrencyType) -> float:
	return _currencies.get(type, 0.0)

func has_enough_currency(type: GameEnums.CurrencyType, amount: float) -> bool:
	return _currencies.get(type, 0.0) >= amount


# ==============================================================================
# PUBLIC API: MODIFIERS
# ==============================================================================
func add_currency(type: GameEnums.CurrencyType, amount: float):
	if not _currencies.has(type): 
		_currencies[type] = 0.0
	
	_currencies[type] += amount
	
	# TODO: Check max amount from definition if you want caps
	# if _definitions.has(type):
	# 	var max_val = _definitions[type].max_amount
	# 	if _currencies[type] > max_val: _currencies[type] = max_val
		
	currency_changed.emit(type, _currencies[type])

func spend_currency(type: GameEnums.CurrencyType, amount: float):
	if has_enough_currency(type, amount):
		_currencies[type] -= amount
		currency_changed.emit(type, _currencies[type])

# Used primarily by the Save System to force a specific state
func set_currency(type: GameEnums.CurrencyType, amount: float):
	_currencies[type] = amount
	currency_changed.emit(type, amount)


# ==============================================================================
# PERSISTENCE (SAVE / LOAD)
# ==============================================================================
func get_save_data() -> Dictionary:
	# JSON only supports String keys, but our Enum is Int.
	# We must convert { 0: 100 } -> { "0": 100 }
	var safe_dict = {}
	for key in _currencies:
		safe_dict[str(key)] = _currencies[key]
	return safe_dict

func load_save_data(data: Dictionary) -> void:
	# Clear old data to prevent ghost currencies
	_currencies.clear()
	
	for key_str in data:
		var key_int = int(key_str) # Convert JSON string back to Enum Int
		var amount = data[key_str]
		
		_currencies[key_int] = amount
		
		# Update UI immediately after loading
		currency_changed.emit(key_int, amount)
