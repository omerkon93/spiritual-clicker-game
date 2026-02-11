extends Node

# PRELOAD YOUR DEFINITIONS HERE DIRECTLY
# This ensures they are available immediately when the game boots.
var currencies: Array[CurrencyDefinition] = [
	preload("res://game_data/game_resources/currencies/money.tres"),
	preload("res://game_data/game_resources/currencies/spirit.tres")
]

var vitals: Array[VitalDefinition] = [
	preload("res://game_data/game_resources/vitals/energy.tres"),
	preload("res://game_data/game_resources/vitals/fullness.tres"),
	preload("res://game_data/game_resources/vitals/focus.tres")
]

func _ready() -> void:
	print("🚀 BOOTSTRAP: Loading Definitions...")
	
	# 1. Initialize Managers IMMEDIATELY
	if not currencies.is_empty():
		CurrencyManager.initialize_currencies(currencies)
	
	if not vitals.is_empty():
		VitalManager.initialize_vitals(vitals)
		
	print("✅ BOOTSTRAP: Definitions Loaded.")
