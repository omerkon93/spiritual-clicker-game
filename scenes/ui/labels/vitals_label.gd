extends Control
class_name VitalsLabel

# DRAG 'Sanity.tres' HERE!
@export var vital_definition: VitalDefinition

@onready var vitals_icon: TextureRect = $HBoxContainer/VitalsIcon
@onready var vitals_label: Label = $HBoxContainer/VitalsLabel
@onready var vitals_progress_bar: TextureProgressBar = %VitalsProgressBar

func _ready():
	if not vital_definition: 
		return

	# 1. Setup Visuals from Resource
	if vitals_icon and vital_definition.icon:
		vitals_icon.texture = vital_definition.icon
	
	# 2. Connect to Manager
	VitalManager.vital_changed.connect(_on_vital_changed)
	
	# 3. Initial Fetch
	var current = VitalManager.get_current(vital_definition.type)
	var max_val = VitalManager.get_max(vital_definition.type)
	
	# Fallback: If VitalManager hasn't set a max yet, use the Resource default
	if max_val == 0: max_val = vital_definition.default_max_value
	
	_update_display(current, max_val)

func _on_vital_changed(type, current, max_val):
	if type == vital_definition.type:
		_update_display(current, max_val)

func _update_display(current: float, max_val: float):
	if vitals_progress_bar:
		vitals_progress_bar.max_value = max_val
		vitals_progress_bar.value = current
		
		# COLOR MAGIC: Sample the gradient based on percentage!
		if vital_definition.gradient:
			var percent = 0.0
			if max_val > 0: percent = current / max_val
			
			# Sample() takes a float from 0.0 to 1.0 and returns the color at that point
			vitals_progress_bar.tint_progress = vital_definition.gradient.gradient.sample(percent)

	if vitals_label:
		vitals_label.text = "%s: %.0f/%.0f" % [vital_definition.display_name, current, max_val]
