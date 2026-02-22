extends Node

# Signals for the UI to listen to
signal research_started(item_id: String, duration: int)
signal research_progressed(item_id: String, remaining: int)
signal research_finished(item_id: String)

# Stores active research: { "tech_id": { "remaining": 60, "total": 60 } }
var active_research: Dictionary = {}

func _ready() -> void:
	if TimeManager:
		TimeManager.time_advanced.connect(_on_time_advanced)

# --- PUBLIC API ---

## The 'Bridge' function the Shop Button was missing
func is_researching(item_id: String) -> bool:
	return active_research.has(item_id)

func start_research(item: GameItem) -> void:
	if active_research.has(item.id): return
	
	active_research[item.id] = {
		"item_id": item.id,
		"remaining": item.research_duration_minutes,
		"total": item.research_duration_minutes
	}
	
	research_started.emit(item.id, item.research_duration_minutes)
	print("🔬 Research Started: %s" % item.display_name)

func get_progress(item_id: String) -> float:
	if not active_research.has(item_id): return 0.0
	var data = active_research[item_id]
	return 1.0 - (float(data.remaining) / float(data.total))

func get_global_research_speed() -> float:
	var total_speed_percent = 0.0
	# Iterate through all items to find research speed boosters
	for item in ItemManager.available_items:
		if ProgressionManager.get_upgrade_level(item.id) > 0:
			for effect in item.effects:
				# Added 'effect != null' right heres
				if effect != null and "stat" in effect and effect.stat == StatDefinition.StatType.RESEARCH_SPEED:
					total_speed_percent += effect.amount
	return 1.0 + total_speed_percent

# --- INTERNAL LOGIC ---

func _on_time_advanced(passed_minutes: int) -> void:
	if active_research.is_empty(): return
	
	var speed_mult = get_global_research_speed()
	var completed_ids = []
	
	# We use keys() to avoid "dictionary changed during size" errors
	for id in active_research.keys():
		var data = active_research[id]
		var effective_progress = int(passed_minutes * speed_mult)
		
		data.remaining -= effective_progress
		research_progressed.emit(id, data.remaining)
		
		if data.remaining <= 0:
			completed_ids.append(id)
			
	for id in completed_ids:
		_complete_research(id)

func _complete_research(id: String) -> void:
	active_research.erase(id)
	var item = ItemManager.find_item_by_id(id)
	if item:
		ItemManager.apply_level_up(item)
		SignalBus.message_logged.emit("Research Complete: %s" % item.display_name, Color.GREEN)
		research_finished.emit(id) # Notify UI to update
