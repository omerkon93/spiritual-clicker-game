extends Node
class_name RewardComponent

# --- STATE ---
var base_vital_gains: Dictionary[int, float] = {}
var base_currency_gains: Dictionary[int, float] = {}

var final_vital_gains: Dictionary[int, float] = {}
var final_currency_gains: Dictionary[int, float] = {}

# Modifiers
var active_multipliers: Dictionary[int, float] = {}
var current_extra_power: float = 0.0 # MEMORY: Stores the upgrade power

# --- SETUP ---
func configure(data: ActionData) -> void:
	base_vital_gains = data.vital_gains.duplicate()
	base_currency_gains = data.currency_gains.duplicate()
	
	# Initial reset
	recalculate_finals(0.0)

# --- PUBLIC API ---

# Called by StreakComponent (Frequent Updates)
func set_multiplier(currency_type: int, mult: float) -> void:
	active_multipliers[currency_type] = mult
	# CRITICAL FIX: Re-use the stored upgrade power, don't reset it to 0.0!
	recalculate_finals(current_extra_power) 

# Called by ActionButton (When Upgrades happen)
func recalculate_finals(extra_currency_power: float) -> void:
	# 1. Update Memory
	current_extra_power = extra_currency_power
	
	# 2. Reset to Base
	final_vital_gains = base_vital_gains.duplicate()
	final_currency_gains = base_currency_gains.duplicate()
	
	# 3. Apply Upgrades (Add Flat Power)
	# Logic: Add power to the first currency found (usually Money)
	if not final_currency_gains.is_empty():
		var first_key: int = final_currency_gains.keys()[0]
		final_currency_gains[first_key] += current_extra_power
	
	# 4. Apply Streak Multipliers (Multiply Total)
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
		
		events.append({
			"text": ResourceConfig.format_gain(type, amount),
			"color": ResourceConfig.get_color(type)
		})
		
	# 2. Give Currency
	for type: int in final_currency_gains:
		var amount: float = final_currency_gains[type]
		Bank.add_currency(type, amount)
		
		events.append({
			"text": ResourceConfig.format_gain(type, amount),
			"color": ResourceConfig.get_color(type)
		})
		
	return events
