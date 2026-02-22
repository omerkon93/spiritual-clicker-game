extends ItemRequirement
class_name CurrencyRequirement

@export var currency: CurrencyDefinition.CurrencyType
@export var amount: int = 10

func is_met() -> bool:
	return CurrencyManager.has_enough_currency(currency, amount)

func consume() -> void:
	CurrencyManager.spend_currency(currency, amount)
	
func get_cost_text() -> String:
	# 1. Ask the Manager for the specific CurrencyDefinition
	var def = CurrencyManager.get_definition(currency)
	
	if def:
		# 2. Use the new helper we added to get the colored, prefixed text (e.g., "[color=#FFD700]$100[/color]")
		return def.format_cost(amount)
	
	# Fallback just in case the definition is missing
	return NumberFormatter.format_value(amount)
