extends Node

signal upgrade_leveled_up(upgrade_id: String, new_level: int)

# Key: String (Upgrade ID), Value: Int (Level)
var upgrade_levels: Dictionary = {}

# The central list of ALL shop items
var available_upgrades: Array[LevelableUpgrade] = []

# Folders to scan automatically on startup
# Adjust these paths to match your project structure!
const AUTO_LOAD_PATHS = [
	"res://game_data/upgrades/",
	"res://game_data/technology/",
	"res://game_data/consumables/" # If you put consumables here
]

var reward_calculator: RewardComponent

func _ready() -> void:
	# 1. Setup Reward Component
	reward_calculator = RewardComponent.new()
	add_child(reward_calculator)
	
	# 2. Run the Auto-Loader
	_scan_for_upgrades()

# --- CHANGED: We now look up by String ID, not Stat Enum ---
func get_upgrade_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)

func try_purchase_level(upgrade: LevelableUpgrade) -> bool:
	var cost = get_current_cost(upgrade)
	
	if not Bank.has_enough_currency(upgrade.cost_currency, cost):
		return false
		
	Bank.spend_currency(upgrade.cost_currency, cost)
	
	# --- NEW: ACTION TRIGGER LOGIC ---
	if upgrade.on_purchase_action:
		_execute_action_rewards(upgrade.on_purchase_action)
		
		# For Consumables, we usually DON'T want to increase the cost/level
		if upgrade.upgrade_type == LevelableUpgrade.UpgradeType.CONSUMABLE:
			# Just return true, don't increment level
			if upgrade.audio_on_purchase:
				SoundManager.play_sfx(upgrade.audio_on_purchase)
			return true

	# --- EXISTING LEVEL UP LOGIC (For Tools/Tech) ---
	var current_lvl = get_upgrade_level(upgrade.id)
	var new_lvl = current_lvl + 1
	upgrade_levels[upgrade.id] = new_lvl
	
	if upgrade.unlock_currency != GameEnums.CurrencyType.NONE:
		Bank.add_currency(upgrade.unlock_currency, upgrade.unlock_amount)
	
	upgrade_leveled_up.emit(upgrade.id, new_lvl)
	return true

func get_current_cost(upgrade: LevelableUpgrade) -> float:
	# Use ID for lookup
	var current_level = get_upgrade_level(upgrade.id) 
	return upgrade.base_cost * pow(upgrade.cost_multiplier, current_level)

func add_available_upgrade(upgrade: LevelableUpgrade):
	# Prevent duplicates
	if not available_upgrades.any(func(x): return x.id == upgrade.id):
		available_upgrades.append(upgrade)
		# Optional: Sort by price or name so the shop looks tidy
		# available_upgrades.sort_custom(func(a, b): return a.base_cost < b.base_cost)

func _scan_for_upgrades() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
	
	print("UpgradeManager: Loaded %d items." % available_upgrades.size())

func _load_dir_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					_load_dir_recursive(path + "/" + file_name)
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var full_path = path + "/" + file_name
					var resource = load(full_path)
					if resource is LevelableUpgrade:
						add_available_upgrade(resource)
			
			file_name = dir.get_next()
	else:
		print("Error: Could not open path: ", path)

func _execute_action_rewards(action: ActionData) -> void:
	# 1. Configure
	reward_calculator.configure(action)
	
	# 2. Calculate (Get the array of results)
	var rewards_log = reward_calculator.deliver_rewards() 
	
	# 3. VISUAL FEEDBACK
	var spawn_pos = get_viewport().get_mouse_position()
	
	for event in rewards_log:
		# FIX: Send Position FIRST, then Text, then Color
		SignalBus.request_floating_text.emit(
			spawn_pos,       # Arg 1: Position
			event.text,      # Arg 2: Text
			event.color      # Arg 3: Color
		)
