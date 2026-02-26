extends VBoxContainer
class_name ResearchSectionUI

# --- NODES ---
@onready var research_title: Label = $TechTitleLabel
@onready var research_bar: ProgressBar = $ProgressBar
@onready var research_time: Label = $TimeRemainingLabel

# --- STATE ---
var current_research_id: String = ""

func _ready() -> void:
	hide() # Hidden by default until research starts
	
	ResearchManager.research_started.connect(_on_research_started)
	ResearchManager.research_progressed.connect(_on_research_progressed)
	ResearchManager.research_finished.connect(_on_research_finished)

# ==============================================================================
# LOGIC
# ==============================================================================
func _on_research_started(item_id: String, duration: int) -> void:
	var item = ItemManager.find_item_by_id(item_id)
	if not item: return

	current_research_id = item_id
	research_title.text = "Researching: " + item.display_name
	
	research_bar.max_value = duration
	research_bar.value = 0
	
	show()
	_update_research_time(duration)

func _on_research_progressed(item_id: String, remaining: int) -> void:
	if item_id != current_research_id: return
	
	research_bar.value = research_bar.max_value - remaining
	_update_research_time(remaining)

func _on_research_finished(item_id: String) -> void:
	if item_id == current_research_id:
		hide()
		current_research_id = ""

func _update_research_time(work_remaining: int) -> void:
	var speed = ResearchManager.get_global_research_speed()
	if speed <= 0: speed = 1.0 # Safety
	
	var real_minutes = work_remaining / speed
	var hours = floor(real_minutes / 60.0)
	var mins = int(real_minutes) % 60
	
	if hours > 0:
		research_time.text = "%dh %dm remaining" % [hours, mins]
	else:
		research_time.text = "%dm remaining" % mins
		
	if speed > 1.0:
		research_time.text += " (x%.1f)" % speed
