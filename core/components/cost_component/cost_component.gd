extends Node
class_name CostComponent

signal check_failed(reason_type: int)

# --- STATE ---
var base_vital_costs: Dictionary[int, float] = {}
var base_currency_costs: Dictionary[int, float] = {}

var final_vital_costs: Dictionary[int, float] = {}
var final_currency_costs: Dictionary[int, float] = {}

# New: A storage for temporary penalties (Key: VitalID, Value: Extra Amount)
var active_penalties: Dictionary[int, float] = {}

# --- SETUP ---
func configure(data: ActionData) -> void:
	base_vital_costs = data.vital_costs.duplicate()
	base_currency_costs = data.currency_costs.duplicate()
	recalculate_finals()

# --- PUBLIC API ---

# The Button calls this when the streak changes
# Example: set_penalty(GameEnums.VitalType.FOCUS, 20.0)
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
		
		# If this vital exists in the base costs, add to it
		if final_vital_costs.has(type):
			final_vital_costs[type] += penalty
		# If it didn't exist (e.g. usually costs 0 Focus), add it now
		else:
			final_vital_costs[type] = penalty

func check_affordability() -> bool:
	# 1. Check Vitals (Using FINAL costs)
	for type: int in final_vital_costs:
		var cost: float = final_vital_costs[type]
		if _should_skip_sanity(type): continue
		
		if not VitalManager.has_enough(type, cost):
			check_failed.emit(type)
			return false

	# 2. Check Currency (Using FINAL costs)
	for type: int in final_currency_costs:
		var cost: float = final_currency_costs[type]
		if not Bank.has_enough_currency(type, cost):
			check_failed.emit(type)
			return false
			
	return true

func pay_all() -> void:
	# Pay Vitals
	for type: int in final_vital_costs:
		if _should_skip_sanity(type): continue
		VitalManager.consume(type, final_vital_costs[type])
	
	# Pay Currency
	for type: int in final_currency_costs:
		Bank.spend_currency(type, final_currency_costs[type])

# --- HELPERS ---
func _should_skip_sanity(type: int) -> bool:
	if type == GameEnums.VitalType.SANITY:
		if Bank.get_currency_amount(GameEnums.CurrencyType.SPIRIT) <= 0:
			return true
	return false
