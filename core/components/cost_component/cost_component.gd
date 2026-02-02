extends Node
class_name CostComponent

signal check_failed(reason_type: int)

# --- STATE ---
var base_vital_costs: Dictionary[int, float] = {}
var base_currency_costs: Dictionary[int, float] = {}

var final_vital_costs: Dictionary[int, float] = {}
var final_currency_costs: Dictionary[int, float] = {}

# Storage for temporary penalties (Key: VitalID, Value: Extra Amount)
var active_penalties: Dictionary[int, float] = {}

# --- BURNOUT SETTINGS ---
# Vitals listed here allow you to go into debt (spend down to 0 even if you can't afford full cost)
var burnout_vitals: Array[int] = [GameEnums.VitalType.FOCUS]

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
	# 1. Reset
	final_vital_costs = base_vital_costs.duplicate()
	final_currency_costs = base_currency_costs.duplicate()
	
	# 2. Apply Penalties
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
		if _should_skip_sanity(type): continue
		
		# --- BURNOUT LOGIC START ---
		# If this vital allows burnout, and we have ANY amount left...
		if type in burnout_vitals and VitalManager.get_current(type) > 0:
			# We allow the action to proceed (we will drain the rest in pay_all)
			continue 
		# --- BURNOUT LOGIC END ---

		# Standard Strict Check
		if not VitalManager.has_enough(type, cost):
			check_failed.emit(type)
			return false

	# 2. Check Currency
	for type: int in final_currency_costs:
		var cost: float = final_currency_costs[type]
		if not Bank.has_enough_currency(type, cost):
			check_failed.emit(type)
			return false
			
	# If we made it here, everything is affordable!
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
			VitalManager.consume(type, amount_to_consume)
		else:
			# Strict Payment
			VitalManager.consume(type, cost)
	
	# Pay Currency
	for type: int in final_currency_costs:
		Bank.spend_currency(type, final_currency_costs[type])

# --- HELPERS ---
func _should_skip_sanity(type: int) -> bool:
	if type == GameEnums.VitalType.SANITY:
		if Bank.get_currency_amount(GameEnums.CurrencyType.SPIRIT) <= 0:
			return true
	return false
