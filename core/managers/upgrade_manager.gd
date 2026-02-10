extends Node

# Folders to scan automatically on startup
# Adjust these paths to match your project structure!
const AUTO_LOAD_PATHS = [
	"res://game_data/game_progression/upgrades/",
	"res://game_data/game_progression/technology/",
	"res://game_data/consumables/" # If you put consumables here
]

# --- SIGNALS ---
signal upgrade_leveled_up(id: String, new_level: int)

# --- STATE ---
# This Dictionary holds your save data: { "upgrade_id": level }
var _unlocked_upgrades: Dictionary = {}   # <--- THIS IS MISSING

# --- CONFIGURATION ---
# (Your existing lists of upgrades go here...)
var available_upgrades: Array[LevelableUpgrade] = []
# Key: String (Upgrade ID), Value: Int (Level)
var upgrade_levels: Dictionary = {}

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
	
	if not CurrencyManager.has_enough_currency(upgrade.cost_currency, cost):
		return false
		
	CurrencyManager.spend_currency(upgrade.cost_currency, cost)
	
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
		CurrencyManager.add_currency(upgrade.unlock_currency, upgrade.unlock_amount)
	
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

func try_purchase_upgrade(upgrade: LevelableUpgrade) -> bool:
	# 1. Get current state
	var current_lvl = get_upgrade_level(upgrade.id)
	
	# 2. Safety Check: Is it already maxed?
	if upgrade.max_level != -1 and current_lvl >= upgrade.max_level:
		return false

	# 3. Calculate Cost
	# Formula: Base Cost * (Multiplier ^ Current Level)
	var cost = upgrade.base_cost * pow(upgrade.cost_multiplier, current_lvl)
	
	# 4. Check Affordability (Assuming Money for now)
	# If you want upgrades to cost other things, you'd check that here.
	if not CurrencyManager.has_enough_currency(GameEnums.CurrencyType.MONEY, cost):
		return false
		
	# 5. Purchase!
	CurrencyManager.remove_currency(GameEnums.CurrencyType.MONEY, cost)
	level_up(upgrade.id) # This updates the dictionary and emits the signal
	
	return true

func level_up(upgrade_id: String) -> void:
	var current_val = 0
	if _unlocked_upgrades.has(upgrade_id):
		current_val = _unlocked_upgrades[upgrade_id]
	
	_unlocked_upgrades[upgrade_id] = current_val + 1
	
	# Emit signal so the UI knows to refresh
	upgrade_leveled_up.emit(upgrade_id, _unlocked_upgrades[upgrade_id])

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

# Tries to buy an upgrade. Returns true if successful.
