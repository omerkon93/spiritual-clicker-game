extends Node
class_name RewardComponent

# --- STATE ---
var base_vital_gains: Dictionary = {}
var base_currency_gains: Dictionary = {}

var final_vital_gains: Dictionary = {}
var final_currency_gains: Dictionary = {}

# Modifiers
var active_multipliers: Dictionary = {}
var current_extra_power: float = 0.0

# --- SETUP ---
func configure(data: ActionData) -> void:
	base_vital_gains = data.vital_gains.duplicate()
	base_currency_gains = data.currency_gains.duplicate()
	
	# Initial calculation (Power starts at 0)
	recalculate_finals(0.0)

# --- PUBLIC API ---

# Called by StreakComponent (Frequent Updates)
func set_multiplier(currency_type: int, mult: float) -> void:
	active_multipliers[currency_type] = mult
	# RE-CALCULATE: Use the stored power so we don't lose upgrade bonuses!
	recalculate_finals(current_extra_power)

# Called by ActionButton (When Upgrades happen)
func recalculate_finals(extra_currency_power: float) -> void:
	# 1. Update Memory
	current_extra_power = extra_currency_power
	
	# 2. Reset to Base
	final_vital_gains = base_vital_gains.duplicate()
	final_currency_gains = base_currency_gains.duplicate()
	
	# 3. Apply Upgrades (Add Flat Power)
	if current_extra_power > 0:
		# Priority: Add to Money first
		if final_currency_gains.has(CurrencyDefinition.CurrencyType.MONEY):
			final_currency_gains[CurrencyDefinition.CurrencyType.MONEY] += current_extra_power
		# Fallback: Add to the first currency found (e.g., Spirit)
		elif not final_currency_gains.is_empty():
			var first_key = final_currency_gains.keys()[0]
			final_currency_gains[first_key] += current_extra_power
	
	# 4. Apply Streak Multipliers (Multiply Total)
	# Logic: (Base + Upgrade) * Multiplier
	for type: int in final_currency_gains:
		var mult: float = active_multipliers.get(type, 1.0)
		final_currency_gains[type] = final_currency_gains[type] * mult

# --- ACTION ---
func deliver_rewards() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	
	# 1. Give Vitals
	for type: int in final_vital_gains:
		var amount: float = final_vital_gains[type]
		VitalManager.restore(type, amount)
		
		if amount > 0:
			events.append(_format_event(type, amount, true))
		
	# 2. Give Currency
	for type: int in final_currency_gains:
		var amount: float = final_currency_gains[type]
		CurrencyManager.add_currency(type, amount)
		
		if amount > 0:
			events.append(_format_event(type, amount, false))
		
	return events


# --- HELPER ---
func _format_event(type: int, amount: float, is_vital: bool) -> Dictionary:
	var text = ""
	var color = Color.WHITE
	
	if is_vital:
		# FIX: Use find_key() to safely get the name, regardless of the ID value
		var vital_name = VitalDefinition.VitalType.find_key(type)
		if vital_name:
			vital_name = vital_name.capitalize()
		else:
			vital_name = "Unknown Vital"
			
		text = "+%d %s" % [amount, vital_name]
		color = Color.GREEN_YELLOW 
	else:
		if type == CurrencyDefinition.CurrencyType.MONEY:
			text = "+$%d" % amount
			color = Color.GOLD
		else:
			# FIX: Use find_key() here too for safety
			var curr_name = CurrencyDefinition.CurrencyType.find_key(type)
			if curr_name:
				curr_name = curr_name.capitalize()
			else:
				curr_name = "Currency"
				
			text = "+%d %s" % [amount, curr_name]
			color = Color.CYAN

	return {"text": text, "color": color}
