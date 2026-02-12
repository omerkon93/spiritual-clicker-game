extends Node

# ==============================================================================
# CONFIGURATION
# ==============================================================================
const AUTO_LOAD_PATHS = [
	"res://game_data/game_progression/upgrades/",
	"res://game_data/game_progression/technology/",
	"res://game_data/consumables/" 
]

# The master list of all item definitions (The "Catalog")
var available_items: Array[LevelableUpgrade] = []

# Internal logic for rewards
var reward_calculator: RewardComponent

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	reward_calculator = RewardComponent.new()
	add_child(reward_calculator)
	_scan_for_items()

# ==============================================================================
# PUBLIC API
# ==============================================================================
func get_current_cost(item: LevelableUpgrade) -> float:
	# REFACTOR: Get level from ProgressionManager
	var current_level = ProgressionManager.get_upgrade_level(item.id) 
	return item.base_cost * pow(item.cost_multiplier, current_level)

func try_purchase_item(item: LevelableUpgrade) -> bool:
	# 1. Validation
	var current_lvl = ProgressionManager.get_upgrade_level(item.id)
	if item.max_level != -1 and current_lvl >= item.max_level:
		return false

	# 2. Check Cost
	var cost = get_current_cost(item)
	if not CurrencyManager.has_enough_currency(item.cost_currency, cost):
		return false
		
	# 3. Process Payment
	CurrencyManager.spend_currency(item.cost_currency, cost)
	
	# 4. Handle Consumable/Action Triggers
	if item.on_purchase_action:
		_execute_action_rewards(item.on_purchase_action)
		
		# Consumables are one-offs; they usually don't gain levels or increase cost
		if item.upgrade_type == LevelableUpgrade.UpgradeType.CONSUMABLE:
			if item.audio_on_purchase:
				SoundManager.play_sfx(item.audio_on_purchase)
			return true

	# 5. Finalize Level Up (for Persistent Items)
	_apply_level_up(item)
	return true

# ==============================================================================
# PRIVATE HELPERS
# ==============================================================================
func _apply_level_up(item: LevelableUpgrade) -> void:
	# REFACTOR: Tell ProgressionManager to update state
	ProgressionManager.increment_upgrade_level(item.id)
	
	# Apply instant rewards (like unlocking a new currency type)
	if item.unlock_currency != GameEnums.CurrencyType.NONE:
		CurrencyManager.add_currency(item.unlock_currency, item.unlock_amount)

func _execute_action_rewards(action: ActionData) -> void:
	reward_calculator.configure(action)
	var rewards_log = reward_calculator.deliver_rewards() 
	
	var spawn_pos = get_viewport().get_mouse_position()
	for event in rewards_log:
		SignalBus.request_floating_text.emit(spawn_pos, event.text, event.color)

# ==============================================================================
# AUTO-LOADER (The "Catalog" Builder)
# ==============================================================================
func _scan_for_items() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
	print("📦 ItemManager: Loaded %d items into catalog." % available_items.size())

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
					var resource = load(path + "/" + file_name)
					if resource is LevelableUpgrade:
						if not available_items.any(func(x): return x.id == resource.id):
							available_items.append(resource)
			file_name = dir.get_next()

# NOTE: Save/Load logic removed. ItemManager is now stateless (just logic + catalog).
# ProgressionManager handles the saving of levels.
