extends VBoxContainer
class_name ResearchSectionUI

@export var research_item_scene: PackedScene
@onready var research_list: VBoxContainer = $ResearchList

func _ready() -> void:
	ResearchManager.research_started.connect(_on_research_started)
	ResearchManager.research_progressed.connect(_on_research_progressed)
	ResearchManager.research_finished.connect(_on_research_finished) # Note: changed to 'finished' to match your manager

# --- SIGNAL CALLBACKS ---

func _on_research_started(item_id: String, duration: int) -> void:
	# 1. Grab the item from the database to get its title
	var item = ItemManager.find_item_by_id(item_id)
	var tech_title = item.display_name if item else "Unknown Tech"
	
	# 2. Spawn the UI element
	var ui_node = research_item_scene.instantiate() as ResearchItemUI
	research_list.add_child(ui_node)
	
	# 3. Setup (Current time is 0.0 at start, total time is the duration)
	ui_node.setup(item_id, tech_title, 0.0, float(duration))

func _on_research_progressed(item_id: String, remaining: int) -> void:
	for child in research_list.get_children():
		if child is ResearchItemUI and child.tech_id == item_id:
			# Your manager passes 'remaining', but the UI needs 'current_time'.
			# We can calculate current time by subtracting remaining from the max_value!
			var total_time = child.progress_bar.max_value
			var current_time = total_time - float(remaining)
			
			child.update_progress(current_time, total_time)
			break

func _on_research_finished(item_id: String) -> void:
	for child in research_list.get_children():
		if child is ResearchItemUI and child.tech_id == item_id:
			child.queue_free() 
			break
