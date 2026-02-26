extends PanelContainer
class_name QuestItemUI

# --- NODES ---
@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel

# --- STATE ---
var quest_id: String = ""

func setup(quest: QuestData) -> void:
	quest_id = quest.id
	title_label.text = quest.title
	desc_label.text = quest.description
	
	# Initialize the progress bar max value
	progress_bar.max_value = quest.required_amount
	update_progress(0, quest.required_amount)

func update_progress(current: int, required: int) -> void:
	progress_bar.value = current
	progress_label.text = str(current) + " / " + str(required)
	
	# Optional: Add a little juice when progress is made
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
