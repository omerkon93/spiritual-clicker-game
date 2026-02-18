extends ItemRequirement
class_name CurrencyRequirement

@export var currency: CurrencyDefinition.CurrencyType
@export var amount: int = 10

func is_met() -> bool:
	return CurrencyManager.has_enough_currency(currency, amount)

func consume() -> void:
	CurrencyManager.spend_currency(currency, amount)
	
func get_cost_text() -> String:
	# Reformats "100" to "$100" (or similar)
	return NumberFormatter.format_value(amount)
