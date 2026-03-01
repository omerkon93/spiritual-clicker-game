extends Node

# Signals for the UI to listen to
signal research_started(item_id: String, duration: int)
signal research_progressed(item_id: String, remaining: int)
signal research_finished(item_id: String)

# Stores active research data
var active_research: Dictionary = {}
# NEW: Tracks the strict order of research (First in, First out)
var research_queue: Array[String] = []

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
	
	# NEW: Add it to the back of the line
	research_queue.append(item.id) 
	
	research_started.emit(item.id, item.research_duration_minutes)
	print("🔬 Research Queued: %s" % item.display_name)

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
	if research_queue.is_empty(): return
	
	var speed_mult = get_global_research_speed()
	var effective_progress = int(passed_minutes * speed_mult)
	
	# Process the queue as long as we have progress to spend and items in line
	while effective_progress > 0 and not research_queue.is_empty():
		# Only look at the first item in line
		var current_id = research_queue[0]
		var data = active_research[current_id]
		
		if effective_progress >= data.remaining:
			# We have enough time to finish this research completely!
			effective_progress -= data.remaining
			data.remaining = 0
			research_progressed.emit(current_id, 0)
			
			_complete_research(current_id)
		else:
			# Not enough time to finish, just apply the progress and stop
			data.remaining -= effective_progress
			effective_progress = 0 # This breaks the while loop
			research_progressed.emit(current_id, data.remaining)

func _complete_research(id: String) -> void:
	active_research.erase(id)
	
	# NEW: Remove it from the line!
	research_queue.erase(id) 
	
	var item = ItemManager.find_item_by_id(id)
	if item:
		ItemManager.apply_level_up(item)
		SignalBus.message_logged.emit("Research Complete: %s" % item.display_name, Color.GREEN)
		research_finished.emit(id)
