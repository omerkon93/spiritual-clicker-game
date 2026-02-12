extends Node

# Signals
signal upgrade_leveled_up(id: String, new_level: int)
signal flag_changed(flag_id: String, value: bool)
signal milestone_unlocked(flag_id: String, description: String)

# --- CONFIGURATION ---
const MILESTONE_PATH = "res://game_data/game_progression/milestones/"

# --- STATE ---
var upgrade_levels: Dictionary = {}
var story_flags: Dictionary = {}

# --- DATABASE ---
var all_milestones: Array[Milestone] = []

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	_load_milestones()
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	if CurrencyManager:
		CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	if VitalManager:
		if VitalManager.has_signal("vital_changed"):
			VitalManager.vital_changed.connect(_on_vital_changed)

func _load_milestones() -> void:
	var dir = DirAccess.open(MILESTONE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var res = load(MILESTONE_PATH + "/" + file_name)
				if res is Milestone:
					all_milestones.append(res)
			file_name = dir.get_next()
		print("🏆 ProgressionManager: Loaded %d milestones." % all_milestones.size())
	else:
		push_error("ProgressionManager: Could not open folder: " + MILESTONE_PATH)

# ==============================================================================
# CHECK LOGIC
# ==============================================================================
func _on_currency_changed(type: int, _amount: float) -> void:
	for m in all_milestones:
		if m.condition_type == Milestone.UnlockCondition.CURRENCY_THRESHOLD:
			if m.target_currency == type:
				_evaluate_milestone(m)

func _on_upgrade_leveled_internal(id: String, _level: int) -> void:
	for m in all_milestones:
		if m.condition_type == Milestone.UnlockCondition.UPGRADE_LEVEL:
			if m.target_upgrade_id == id:
				_evaluate_milestone(m)

func _on_vital_changed(type: int, _current: float, _max: float) -> void:
	for m in all_milestones:
		# Changed VITAL_VALUE -> VITAL_THRESHOLD
		if m.condition_type == Milestone.UnlockCondition.VITAL_THRESHOLD:
			if m.target_vital == type:
				_evaluate_milestone(m)

func _evaluate_milestone(m: Milestone) -> void:
	if m.target_flag == null: return
	if get_flag(m.target_flag): return 

	var passed: bool = false
	var current_val: float = 0.0
	var target_val: float = 0.0
	
	# 1. Get Values based on Type
	match m.condition_type:
		Milestone.UnlockCondition.CURRENCY_THRESHOLD:
			current_val = CurrencyManager.get_currency_amount(m.target_currency)
			target_val = m.currency_amount
			
		Milestone.UnlockCondition.UPGRADE_LEVEL:
			current_val = float(get_upgrade_level(m.target_upgrade_id))
			target_val = float(m.upgrade_level)
			
		Milestone.UnlockCondition.VITAL_THRESHOLD:
			if VitalManager.has_method("get_vital_value"):
				current_val = VitalManager.get_vital_value(m.target_vital)
				target_val = m.vital_amount

	# 2. Compare Values
	if m.is_less_than:
		passed = current_val <= target_val # Lower Than Logic
	else:
		passed = current_val >= target_val # Higher Than Logic (Default)

	if passed:
		unlock_milestone(m.target_flag.id, m.notification_text)

func unlock_milestone(flag_id: String, display_text: String) -> void:
	if not get_flag(flag_id):
		set_flag(flag_id, true)
		milestone_unlocked.emit(flag_id, display_text)
		
		# Visuals
		print("🏆 Milestone Reached: ", display_text)
		SignalBus.message_logged.emit(display_text, Color.GOLD)

# ==============================================================================
# PUBLIC API
# ==============================================================================
func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)

func increment_upgrade_level(id: String, amount: int = 1) -> void:
	var current = get_upgrade_level(id)
	var new_level = current + amount
	upgrade_levels[id] = new_level
	upgrade_leveled_up.emit(id, new_level)
	_on_upgrade_leveled_internal(id, new_level)

func get_flag(key) -> bool:
	var id = _resolve_key(key)
	return story_flags.get(id, false)

func set_flag(key, value: bool = true) -> void:
	var id = _resolve_key(key)
	if story_flags.get(id) != value:
		story_flags[id] = value
		flag_changed.emit(id, value)

func _resolve_key(key) -> String:
	if key is StoryFlag: return key.id
	return str(key)

# ==============================================================================
# PERSISTENCE
# ==============================================================================
func get_save_data() -> Dictionary:
	return { "upgrades": upgrade_levels.duplicate(), "flags": story_flags.duplicate() }

func load_save_data(data: Dictionary) -> void:
	if data.has("upgrades"): upgrade_levels = data["upgrades"]
	if data.has("flags"): story_flags = data["flags"]
	
	for id in upgrade_levels: upgrade_leveled_up.emit(id, upgrade_levels[id])
	for flag in story_flags: flag_changed.emit(flag, story_flags[flag])
	
	for m in all_milestones:
		_evaluate_milestone(m)
