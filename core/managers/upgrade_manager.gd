extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================
signal upgrade_leveled_up(id: String, new_level: int)


# ==============================================================================
# DATA STORAGE & CONFIGURATION
# ==============================================================================
# Folders to scan automatically on startup
const AUTO_LOAD_PATHS = [
	"res://game_data/game_progression/upgrades/",
	"res://game_data/game_progression/technology/",
	"res://game_data/consumables/" 
]

# Static Config: The master list of all upgrade resources found in the folders
var available_upgrades: Array[LevelableUpgrade] = []

# Dynamic State: { "upgrade_id": level_int }
var _unlocked_upgrades: Dictionary = {}

# Internal logic component for calculating reward values
var reward_calculator: RewardComponent


# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# 1. Setup Reward Component for logic execution
	reward_calculator = RewardComponent.new()
	add_child(reward_calculator)
	
	# 2. Run the Auto-Loader to find all upgrade resources
	_scan_for_upgrades()


# ==============================================================================
# 2. PUBLIC API: GETTERS
# ==============================================================================
func get_upgrade_level(upgrade_id: String) -> int:
	return _unlocked_upgrades.get(upgrade_id, 0)

func get_current_cost(upgrade: LevelableUpgrade) -> float:
	var current_level = get_upgrade_level(upgrade.id) 
	# Formula: Base Cost * (Multiplier ^ Current Level)
	return upgrade.base_cost * pow(upgrade.cost_multiplier, current_level)


# ==============================================================================
# 3. PUBLIC API: PURCHASE LOGIC
# ==============================================================================
func try_purchase_upgrade(upgrade: LevelableUpgrade) -> bool:
	# 1. Validation: Is it already at max level?
	var current_lvl = get_upgrade_level(upgrade.id)
	if upgrade.max_level != -1 and current_lvl >= upgrade.max_level:
		return false

	# 2. Calculate Cost
	var cost = get_current_cost(upgrade)
	
	# 3. Check Affordability
	if not CurrencyManager.has_enough_currency(upgrade.cost_currency, cost):
		return false
		
	# 4. Process Payment
	CurrencyManager.spend_currency(upgrade.cost_currency, cost)
	
	# 5. Handle Specialized Action Triggers (e.g., Consumables)
	if upgrade.on_purchase_action:
		_execute_action_rewards(upgrade.on_purchase_action)
		
		# Consumables don't increase levels/costs; they are "one-off" triggers
		if upgrade.upgrade_type == LevelableUpgrade.UpgradeType.CONSUMABLE:
			if upgrade.audio_on_purchase:
				SoundManager.play_sfx(upgrade.audio_on_purchase)
			return true

	# 6. Finalize Level Up (for Tools/Tech)
	_apply_level_up(upgrade)
	return true


# ==============================================================================
# 4. PRIVATE HELPERS
# ==============================================================================
func _apply_level_up(upgrade: LevelableUpgrade) -> void:
	var current_lvl = get_upgrade_level(upgrade.id)
	var new_lvl = current_lvl + 1
	_unlocked_upgrades[upgrade.id] = new_lvl
	
	# Apply any instant currency rewards defined in the upgrade
	if upgrade.unlock_currency != GameEnums.CurrencyType.NONE:
		CurrencyManager.add_currency(upgrade.unlock_currency, upgrade.unlock_amount)
	
	upgrade_leveled_up.emit(upgrade.id, new_lvl)

func _execute_action_rewards(action: ActionData) -> void:
	reward_calculator.configure(action)
	var rewards_log = reward_calculator.deliver_rewards() 
	
	# Visual Feedback: Spawn floating text at mouse position
	var spawn_pos = get_viewport().get_mouse_position()
	for event in rewards_log:
		SignalBus.request_floating_text.emit(spawn_pos, event.text, event.color)

func _add_available_upgrade(upgrade: LevelableUpgrade) -> void:
	if not available_upgrades.any(func(x): return x.id == upgrade.id):
		available_upgrades.append(upgrade)


# ==============================================================================
# 5. AUTO-LOADER LOGIC
# ==============================================================================
func _scan_for_upgrades() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
	print("📦 UpgradeManager: Automatically loaded %d items." % available_upgrades.size())

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
					print("🔍 Found file: ", full_path)
					var resource = load(path + "/" + file_name)
					if resource is LevelableUpgrade:
						_add_available_upgrade(resource)
			file_name = dir.get_next()
	else:
		print("❌ UpgradeManager Error: Path not found: ", path)


# ==============================================================================
# 6. PERSISTENCE (SAVE / LOAD)
# ==============================================================================
func get_save_data() -> Dictionary:
	return _unlocked_upgrades.duplicate()

func load_save_data(data: Dictionary) -> void:
	_unlocked_upgrades = data
	
	# Force UI refresh for all loaded levels
	for id in _unlocked_upgrades:
		upgrade_leveled_up.emit(id, _unlocked_upgrades[id])
