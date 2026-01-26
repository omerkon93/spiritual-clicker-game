extends Node

signal upgrade_leveled_up(upgrade_id: String, new_level: int)

# Key: String (Upgrade ID), Value: Int (Level)
var upgrade_levels: Dictionary = {}

# --- CHANGED: We now look up by String ID, not Stat Enum ---
func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)

func try_purchase_level(upgrade: LevelableUpgrade) -> bool:
	var cost = get_current_cost(upgrade)
	
	if not Bank.has_enough_currency(upgrade.cost_currency, cost):
		return false
		
	Bank.spend_currency(upgrade.cost_currency, cost)
	
	# Track level using the UNIQUE ID string
	var current_lvl = get_upgrade_level(upgrade.id)
	var new_lvl = current_lvl + 1
	upgrade_levels[upgrade.id] = new_lvl
	
	if upgrade.unlock_currency != GameEnums.CurrencyType.NONE:
		Bank.add_currency(upgrade.unlock_currency, upgrade.unlock_amount)
		# Optional: Add a log message so the player knows what happened
		SignalBus.message_logged.emit("Unlocked new resource!", Color.VIOLET)
	
	# Signal now sends the ID
	upgrade_leveled_up.emit(upgrade.id, new_lvl)
	return true

func get_current_cost(upgrade: LevelableUpgrade) -> float:
	# Use ID for lookup
	var current_level = get_upgrade_level(upgrade.id) 
	return upgrade.base_cost * pow(upgrade.cost_multiplier, current_level)
