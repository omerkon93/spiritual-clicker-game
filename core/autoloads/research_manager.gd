extends Node

signal research_started(item_id: String, duration: int)
signal research_progressed(item_id: String, remaining: int)
signal research_completed(item_id: String)

# Stores active research: { "tech_001": { "remaining": 60, "total": 60 } }
var active_research: Dictionary = {}

func _ready() -> void:
	# Listen for time passing (requires updated TimeManager)
	if TimeManager:
		TimeManager.time_advanced.connect(_on_time_advanced)

# --- PUBLIC API ---
func start_research(item: GameItem) -> void:
	if active_research.has(item.id): return
	
	active_research[item.id] = {
		"item_id": item.id,
		"remaining": item.research_duration_minutes,
		"total": item.research_duration_minutes
	}
	
	research_started.emit(item.id, item.research_duration_minutes)
	print("🔬 Research Started: %s (%d mins)" % [item.display_name, item.research_duration_minutes])

func get_progress(item_id: String) -> float:
	if not active_research.has(item_id): return 0.0
	var data = active_research[item_id]
	if data.total == 0: return 1.0
	return 1.0 - (float(data.remaining) / float(data.total))

func get_global_research_speed() -> float:
	var total_speed_percent = 0.0
	
	for item in ItemManager.available_items:
		if ProgressionManager.get_upgrade_level(item.id) > 0:
			for effect in item.effects:
				if "stat" in effect and "amount" in effect:
					if effect.stat == StatDefinition.StatType.RESEARCH_SPEED:
						total_speed_percent += effect.amount

	return 1.0 + total_speed_percent

func calculate_global_research_speed() -> float:
	var total_speed_percent = 0.0
	
	# Iterate all OWNED items to check for Research Speed effects
	for item in ItemManager.available_items:
		if ProgressionManager.get_upgrade_level(item.id) > 0:
			for effect in item.effects:
				# Duck-typing check for StatEffect properties
				if "stat" in effect and "amount" in effect:
					if effect.stat == StatDefinition.StatType.RESEARCH_SPEED:
						# Assuming amount 0.1 means +10% speed
						total_speed_percent += effect.amount

	return 1.0 + total_speed_percent

# --- INTERNAL LOGIC ---
func _on_time_advanced(passed_minutes: int) -> void:
	if active_research.is_empty(): return
	
	# Calculate Global Research Speed from Upgrades
	var speed_mult = calculate_global_research_speed()
	
	var completed_ids = []
	
	for id in active_research:
		var data = active_research[id]
		# Apply Speed Multiplier (1.0 = Normal, 2.0 = Double Speed)
		var effective_progress = int(passed_minutes * speed_mult)
		
		data.remaining -= effective_progress
		research_progressed.emit(id, data.remaining)
		
		if data.remaining <= 0:
			completed_ids.append(id)
			
	for id in completed_ids:
		_complete_research(id)

func _complete_research(id: String) -> void:
	active_research.erase(id)
	
	# Find the item to grant it
	var item = ItemManager.find_item_by_id(id)
	if item:
		# Grant the item using ItemManager's helper
		ItemManager.apply_level_up(item)
		SignalBus.message_logged.emit("Research Complete: %s" % item.display_name, Color.GREEN)
		research_completed.emit(id)

func _find_item_by_id(id: String) -> GameItem:
	for item in ItemManager.available_items:
		if item.id == id: return item
	return null
