extends Node
class_name CostComponent

signal check_failed(reason: String)

# --- STATE ---
var base_vital_costs: Dictionary = {}
var base_currency_costs: Dictionary = {}

var final_vital_costs: Dictionary = {}
var final_currency_costs: Dictionary = {}

var active_penalties: Dictionary = {}

# --- BURNOUT SETTINGS ---
@export var burnout_vitals: Array[GameEnums.VitalType] = [
	GameEnums.VitalType.FOCUS,
	GameEnums.VitalType.ENERGY,
	GameEnums.VitalType.FULLNESS
]

# --- SETUP ---
func configure(data: ActionData) -> void:
	base_vital_costs = data.vital_costs.duplicate()
	base_currency_costs = data.currency_costs.duplicate()
	recalculate_finals()

# --- PUBLIC API ---
func set_penalty(vital_type: int, amount: float) -> void:
	active_penalties[vital_type] = amount
	recalculate_finals()

func recalculate_finals() -> void:
	final_vital_costs = base_vital_costs.duplicate()
	final_currency_costs = base_currency_costs.duplicate()
	
	for type: int in active_penalties:
		var penalty: float = active_penalties[type]
		if final_vital_costs.has(type):
			final_vital_costs[type] += penalty
		else:
			final_vital_costs[type] = penalty

func check_affordability() -> bool:
	# 1. Check Vitals
	for type: int in final_vital_costs:
		var cost: float = final_vital_costs[type]
		
		if type in burnout_vitals:
			# FIX: Changed from >= 1.0 to > 0.0
			# This ensures even 0.1 Energy allows the action to proceed
			if VitalManager.get_current(type) > 0.0: 
				continue 

		# Strict Check (for non-burnout vitals or if vital is exactly 0)
		if not VitalManager.has_enough(type, cost):
			var vital_name = GameEnums.VitalType.find_key(type)
			if vital_name:
				vital_name = vital_name.capitalize()
			else:
				vital_name = "Vital"

			check_failed.emit("Not enough %s!" % vital_name)
			return false

	# 2. Check Currency
	for type: int in final_currency_costs:
		var cost: float = final_currency_costs[type]
		
		if not CurrencyManager.has_enough_currency(type, cost):
			var currency_name = GameEnums.CurrencyType.find_key(type)
			if currency_name:
				currency_name = currency_name.capitalize()
			else:
				currency_name = "Currency"
				
			check_failed.emit("Not enough %s!" % currency_name)
			return false
			
	return true

func pay_all() -> void:
	# Pay Vitals
	for type: int in final_vital_costs:
		var cost: float = final_vital_costs[type]
		
		# --- BURNOUT PAY LOGIC ---
		if type in burnout_vitals:
			# Consume the cost OR whatever is left (whichever is smaller)
			# This drains 0.5 Energy to 0.0 if the cost was 10.
			var available: float = VitalManager.get_current(type)
			var amount_to_consume: float = min(cost, available)
			
			VitalManager.consume(type, amount_to_consume)
		else:
			# Strict Payment
			VitalManager.consume(type, cost)
	
	# Pay Currency
	for type: int in final_currency_costs:
		CurrencyManager.spend_currency(type, final_currency_costs[type])
