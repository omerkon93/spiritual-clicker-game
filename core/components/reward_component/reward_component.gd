extends Node
class_name RewardComponent

# --- STATE ---
var base_vital_gains: Dictionary = {}
var base_currency_gains: Dictionary = {}

var final_vital_gains: Dictionary = {}
var final_currency_gains: Dictionary = {}

var active_multipliers: Dictionary = {}
var current_extra_power: float = 0.0

# --- SETUP ---
func configure(data: ActionData) -> void:
	base_vital_gains = data.vital_gains.duplicate()
	base_currency_gains = data.currency_gains.duplicate()
	recalculate_finals(0.0)

# --- PUBLIC API ---
func set_multiplier(currency_type: int, mult: float) -> void:
	active_multipliers[currency_type] = mult
	recalculate_finals(current_extra_power)

func recalculate_finals(extra_currency_power: float) -> void:
	current_extra_power = extra_currency_power
	
	final_vital_gains = base_vital_gains.duplicate()
	final_currency_gains = base_currency_gains.duplicate()
	
	if current_extra_power != 0:
		if final_currency_gains.has(CurrencyDefinition.CurrencyType.MONEY):
			final_currency_gains[CurrencyDefinition.CurrencyType.MONEY] += current_extra_power
		elif not final_currency_gains.is_empty():
			var first_key = final_currency_gains.keys()[0]
			final_currency_gains[first_key] += current_extra_power
	
	for key in final_currency_gains:
		final_currency_gains[key] = max(0, final_currency_gains[key])

	for type: int in final_currency_gains:
		var mult: float = active_multipliers.get(type, 1.0)
		final_currency_gains[type] = final_currency_gains[type] * mult

# --- ACTION ---
func deliver_rewards() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 1. Give Vitals
	for type: int in final_vital_gains:
		var amount: float = final_vital_gains[type]
		if amount <= 0: continue
		
		VitalManager.restore(type, amount)
		events.append(_format_event(type, amount, true))
		
		# Optional: Also trigger the FloatingText system we just built
		if SignalBus.has_signal("request_resource_text"):
			SignalBus.request_resource_text.emit(mouse_pos, type, amount, false)
		
	# 2. Give Currency
	for type: int in final_currency_gains:
		var amount: float = final_currency_gains[type]
		if amount <= 0: continue
		
		CurrencyManager.add_currency(type, amount)
		events.append(_format_event(type, amount, false))
		
		# Optional: Also trigger the FloatingText system we just built
		if SignalBus.has_signal("request_resource_text"):
			SignalBus.request_resource_text.emit(mouse_pos, type, amount, true)
		
	return events

# --- HELPER (Now Definition-Aware!) ---
func _format_event(type: int, amount: float, is_vital: bool) -> Dictionary:
	var def = null
	if is_vital:
		def = VitalManager.get_definition(type)
	else:
		def = CurrencyManager.get_definition(type)
	
	# Fallback if definition is missing
	if not def:
		return {"text": "+%d" % amount, "color": Color.WHITE}
	
	# 1. Use the display_color from the Resource
	var color = def.display_color
	
	# 2. Use the text_icon from the Resource
	var text = ""
	var amount_str = str(int(amount))
	
	if not is_vital and type == CurrencyDefinition.CurrencyType.MONEY:
		# Format: +$50
		text = "+%s%s" % [def.text_icon, amount_str]
	else:
		# Format: +20 ⚡
		text = "+%s %s" % [amount_str, def.text_icon]

	return {"text": text, "color": color}
