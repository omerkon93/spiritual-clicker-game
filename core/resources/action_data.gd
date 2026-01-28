extends Resource
class_name ActionData

@export_category("Identity")
@export var display_name: String = "Action"
@export var description: String = ""

@export_category("Costs")
@export var vital_costs: Dictionary[int, float] = {} 
@export var currency_costs: Dictionary[int, float] = {}

@export_category("Rewards")
@export var vital_gains: Dictionary[int, float] = {} 
@export var currency_gains: Dictionary[int, float] = {}

@export_category("Feedback")
@export var failure_messages: Dictionary[int, String] = {
	GameEnums.CurrencyType.MONEY: "Not enough money!",
	GameEnums.CurrencyType.SPIRIT: "Not enough spirit!",
	GameEnums.VitalType.ENERGY: "I need to rest...",
	GameEnums.VitalType.FULLNESS: "I need to eat...",
	GameEnums.VitalType.FOCUS: "I need to refocus...",
	GameEnums.VitalType.SANITY: "I'm burning out..."
}
