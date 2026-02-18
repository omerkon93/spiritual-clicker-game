extends PanelContainer

@onready var title_label: Label = $VBoxContainer/TechTitleLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var time_label: Label = $VBoxContainer/TimeRemainingLabel

func _ready() -> void:
	# Hide by default until research starts
	visible = false
	
	# Connect to the Manager signals
	ResearchManager.research_started.connect(_on_research_started)
	ResearchManager.research_progressed.connect(_on_research_progressed)
	ResearchManager.research_completed.connect(_on_research_completed)

func _on_research_started(item_id: String, duration: int) -> void:
	# Find the item display name
	var item = ItemManager.find_item_by_id(item_id)
	title_label.text = "Researching: " + item.display_name
	
	progress_bar.max_value = duration
	progress_bar.value = 0
	visible = true
	_update_time_label(duration)

func _on_research_progressed(_item_id: String, remaining: int) -> void:
	progress_bar.value = progress_bar.max_value - remaining
	_update_time_label(remaining)

func _on_research_completed(_item_id: String) -> void:
	# You could play a little "Ding!" sound here
	visible = false

func _update_time_label(work_remaining: int) -> void:
	# 1. Get current speed (e.g., 1.5 for +50%)
	var speed = ResearchManager.get_global_research_speed()
	
	# 2. Calculate Real Time (Work / Speed)
	# Example: 600 work / 2.0 speed = 300 actual minutes left
	var real_minutes_left = work_remaining / speed
	
	# 3. Format nicely
	var hours = floor(real_minutes_left / 60.0)
	var mins = int(real_minutes_left) % 60
	
	if hours > 0:
		time_label.text = "%dh %dm remaining" % [hours, mins]
	else:
		time_label.text = "%dm remaining" % mins
		
	# Optional: Show speed boost in text
	if speed > 1.0:
		time_label.text += " (x%.1f Speed)" % speed
