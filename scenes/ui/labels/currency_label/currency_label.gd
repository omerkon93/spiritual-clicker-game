extends Control
class_name CurrenciesLabel

# --- DATA ---
@export var monitored_currency: CurrencyDefinition

@export_group("Local Exports")
# --- COMPONENTS ---
# Add a Node named 'CurrencyMonitor' with the script attached
@export var monitor: CurrencyMonitor

# --- UI NODES ---
@export var currency_icon: TextureRect
@export var currency_label: Label

func _ready() -> void:
	if not monitored_currency or not monitor:
		printerr("CurrenciesLabel Error: Missing definition or component.")
		return
	
	# 1. Setup UI Static Data
	if currency_icon and monitored_currency.icon:
		currency_icon.texture = monitored_currency.icon
	
	# 2. Wire up the Component
	monitor.data_updated.connect(_on_data_updated)
	monitor.visibility_requested.connect(_on_visibility_requested)
	
	# 3. Start Monitoring
	monitor.setup(monitored_currency.type)

# --- VIEW LOGIC ---
func _on_data_updated(formatted_amount: String) -> void:
	# The Component gave us the number, we just add the name
	currency_label.text = "%s: %s" % [monitored_currency.display_name, formatted_amount]

func _on_visibility_requested(should_show: bool) -> void:
	visible = should_show
