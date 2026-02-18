extends Node

# ==============================================================================
# CONFIGURATION
# ==============================================================================
const AUTO_LOAD_PATHS = [
	"res://game_data/items/upgrades/",
	"res://game_data/items/technology/",
	"res://game_data/items/consumables/" 
]

var available_items: Array[GameItem] = []
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
func try_purchase_item(item: GameItem) -> bool:
	# ---------------------------------------------------------
	# 1. VALIDATION
	# ---------------------------------------------------------
	if item.item_type != GameItem.ItemType.CONSUMABLE:
		var current_level = ProgressionManager.get_upgrade_level(item.id)
		if current_level >= 1:
			print("❌ ItemManager: Already own %s" % item.display_name)
			return false

	# ---------------------------------------------------------
	# 2. CHECK REQUIREMENTS
	# ---------------------------------------------------------
	for req in item.requirements:
		if req.has_method("is_met") and not req.is_met():
			# Optional: Play a "can't afford" sound here
			return false

	# ---------------------------------------------------------
	# 3. CONSUME COSTS
	# ---------------------------------------------------------
	for req in item.requirements:
		if req.has_method("consume"):
			req.consume()

	# ---------------------------------------------------------
	# 4. RESEARCH INTERCEPTION
	# ---------------------------------------------------------
	if item.item_type == GameItem.ItemType.TECHNOLOGY:
		ResearchManager.start_research(item)
		SignalBus.message_logged.emit("Research Started: %s" % item.display_name, Color.CYAN)
		# We return true so the UI knows the "buy" click was successful
		return true

	# ---------------------------------------------------------
	# 5. IMMEDIATE GRANT (Tools & Consumables)
	# ---------------------------------------------------------
	# If we reached this line, it's not Tech, so we give it immediately
	apply_level_up(item)
	return true

func find_item_by_id(id: String) -> GameItem:
	for item in available_items:
		if item.id == id: return item
	return null

## Grants the rewards, stats, and "Owned" status of an item.
## Called immediately for Tools, or after a timer for Technology.
func apply_level_up(item: GameItem) -> void:
	# A. Apply Effects (Stats, etc.)
	for effect in item.effects:
		if effect.has_method("apply"):
			effect.apply()

	# B. Unlock Story Flag
	if item.story_flag_reward:
		ProgressionManager.set_flag(item.story_flag_reward, true)
		print("🔓 ItemManager: Unlocked Story Flag -> ", item.story_flag_reward.id)

	# C. Trigger Legacy Actions
	if item.on_purchase_action:
		_execute_action_rewards(item.on_purchase_action)

	# D. Persistence (Mark as Owned)
	if item.item_type != GameItem.ItemType.CONSUMABLE:
		ProgressionManager.increment_upgrade_level(item.id)
		ProgressionManager.upgrade_leveled_up.emit(item.id, 1)
	
	# E. Feedback
	if item.item_type != GameItem.ItemType.TECHNOLOGY:
		SignalBus.message_logged.emit("Purchased: %s" % item.display_name, Color.CYAN)
		if item.audio_on_purchase:
			SoundManager.play_sfx(item.audio_on_purchase)

# ==============================================================================
# PRIVATE HELPERS
# ==============================================================================
func _execute_action_rewards(action: ActionData) -> void:
	reward_calculator.configure(action)
	var rewards_log = reward_calculator.deliver_rewards() 
	
	var spawn_pos = get_viewport().get_mouse_position()
	for event in rewards_log:
		SignalBus.request_floating_text.emit(spawn_pos, event.text, event.color)

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
					if resource is GameItem:
						if not available_items.any(func(x): return x.id == resource.id):
							available_items.append(resource)
			file_name = dir.get_next()
