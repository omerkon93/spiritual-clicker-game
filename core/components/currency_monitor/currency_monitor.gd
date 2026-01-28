extends Node
class_name CurrencyMonitor

# --- SIGNALS ---
# Emitted when data changes. We pass the pre-formatted string to keep the View dumb.
signal data_updated(formatted_text: String)
signal visibility_requested(should_show: bool)

# --- STATE ---
var currency_type: int = GameEnums.CurrencyType.NONE

# --- SETUP ---
func setup(type: int) -> void:
	currency_type = type
	
	# 1. Connect
	if not Bank.currency_changed.is_connected(_on_currency_changed):
		Bank.currency_changed.connect(_on_currency_changed)
	
	# 2. Initial Fetch
	var current: float = Bank.get_currency_amount(currency_type)
	_process_update(current)
	_check_initial_visibility(current)

# --- LOGIC ---
func _on_currency_changed(type: int, amount: float) -> void:
	if type == currency_type:
		_process_update(amount)

func _process_update(amount: float) -> void:
	# 1. Format the text (Logic)
	var text: String = NumberFormatter.format_value(amount)
	
	# 2. Check Visibility Rule (Logic)
	# If we just gained money and it was hidden, show it.
	if amount > 0:
		visibility_requested.emit(true)
		
	# 3. Emit Data
	data_updated.emit(text)

func _check_initial_visibility(amount: float) -> void:
	# Always show MONEY, otherwise check if we have > 0
	if currency_type == GameEnums.CurrencyType.MONEY:
		visibility_requested.emit(true)
	elif amount > 0:
		visibility_requested.emit(true)
	else:
		visibility_requested.emit(false)
