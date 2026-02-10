extends Node
class_name CostComponent

# CHANGED: Use String so the UI knows exactly what to display (e.g. "Not enough Energy!")
signal check_failed(reason: String)

# --- STATE ---
var base_vital_costs: Dictionary = {}
var base_currency_costs: Dictionary = {}

var final_vital_costs: Dictionary = {}
var final_currency_costs: Dictionary = {}

# Storage for temporary penalties (Key: VitalID, Value: Extra Amount)
var active_penalties: Dictionary = {}

# --- BURNOUT SETTINGS ---
# Vitals listed here allow you to "spend down to 0" even if you can't afford the full cost.
# (e.g., Spending your last 5 Energy on a 20 Energy task)
var burnout_vitals: Array[int] = [
	GameEnums.VitalType.FOCUS, 
	# Add ENERGY here if you want that behavior
]

# --- SETUP ---
func configure(data: ActionData) -> void:
	# Duplicate ensures we don't modify the original Resource
	base_vital_costs = data.vital_costs.duplicate()
	base_currency_costs = data.currency_costs.duplicate()
	
	recalculate_finals()

# --- PUBLIC API ---

func set_penalty(vital_type: int, amount: float) -> void:
	active_penalties[vital_type] = amount
	recalculate_finals()

func recalculate_finals() -> void:
	# 1. Reset to base
	final_vital_costs = base_vital_costs.duplicate()
	final_currency_costs = base_currency_costs.duplicate()
	
	# 2. Apply Penalties
	for type: int in active_penalties:
		var penalty: float = active_penalties[type]
		
		# If the cost exists, increase it. If not, add a new cost.
		if final_vital_costs.has(type):
			final_vital_costs[type] += penalty
		else:
			final_vital_costs[type] = penalty

func check_affordability() -> bool:
	# 1. Check Vitals
	for type: int in final_vital_costs:
		var cost: float = final_vital_costs[type]
		
		if _should_skip_sanity(type): continue
		
		if type in burnout_vitals:
			if VitalManager.get_current(type) >= 1.0: 
				continue 

		if not VitalManager.has_enough(type, cost):
			var vital_name = GameEnums.VitalType.find_key(type)
			if vital_name:
				vital_name = vital_name.capitalize()
			else:
				vital_name = "Vital"

			check_failed.emit("Not enough %s!" % vital_name)
			return false  # <--- NOTHING should be below this inside the 'if' block

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
			return false # <--- NOTHING should be below this inside the 'if' block
			
	return true

func pay_all() -> void:
	# Pay Vitals
	for type: int in final_vital_costs:
		if _should_skip_sanity(type): continue
		
		var cost: float = final_vital_costs[type]
		
		# --- BURNOUT PAY LOGIC ---
		if type in burnout_vitals:
			# Consume the cost OR whatever is left (whichever is smaller)
			var available: float = VitalManager.get_current(type)
			var amount_to_consume: float = min(cost, available)
			
			# Ensure we don't consume negative amounts
			VitalManager.consume(type, max(0, amount_to_consume))
		else:
			# Strict Payment
			VitalManager.consume(type, cost)
	
	# Pay Currency
	for type: int in final_currency_costs:
		CurrencyManager.spend_currency(type, final_currency_costs[type])

# --- HELPERS ---
func _should_skip_sanity(type: int) -> bool:
	if type == GameEnums.VitalType.SANITY:
		# Example Logic: If you have no Spirit, you stop caring about Sanity
		if CurrencyManager.get_currency_amount(GameEnums.CurrencyType.SPIRIT) <= 0:
			return true
	return false
