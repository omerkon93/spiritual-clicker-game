extends PanelContainer
class_name ResearchItemUI

@onready var title_label: Label = %TechTitleLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var time_label: Label = %TimeRemainingLabel

var tech_id: String = ""

func setup(id: String, title: String, current_time: float, total_time: float) -> void:
	tech_id = id
	title_label.text = "Researching: " + title
	progress_bar.max_value = total_time
	progress_bar.value = current_time
	_update_time_label(total_time - current_time)

func update_progress(current_time: float, total_time: float) -> void:
	progress_bar.value = current_time
	_update_time_label(total_time - current_time)

func _update_time_label(time_left: float) -> void:
	# Optional: Format into MM:SS if needed
	time_label.text = str(ceil(time_left)) + "s remaining"
