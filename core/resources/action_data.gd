extends Resource
class_name ActionData

@export_category("Identity")
@export var display_name: String = ""

@export_category("Events")
# NEW: If set, this string is emitted to SignalBus (for ShopWindowComponent, etc.)
@export var trigger_signal_id: String = ""

@export_category("Costs")
@export var vital_costs: Dictionary[GameEnums.VitalType, float] = {}
@export var currency_costs: Dictionary[GameEnums.CurrencyType, float] = {}

@export_category("Rewards")
@export var vital_gains: Dictionary[GameEnums.VitalType, float] = {}
@export var currency_gains: Dictionary[GameEnums.CurrencyType, float] = {}

@export_category("Messages")
@export var failure_messages: Dictionary[int, String] = {}
