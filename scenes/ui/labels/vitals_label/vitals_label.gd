extends Control
class_name VitalsLabel

# --- DATA ---
@export var vital_definition: VitalDefinition

@export_group("Local Exports")
# --- COMPONENTS ---
@export var monitor: VitalMonitor

# --- UI NODES ---
@export var vitals_icon: TextureRect
@export var vitals_label: Label
@export var vitals_progress_bar: TextureProgressBar

func _ready() -> void:
	if not vital_definition or not monitor: 
		return

	# 1. Setup Static Visuals
	if vitals_icon and vital_definition.icon:
		vitals_icon.texture = vital_definition.icon
	
	# 2. Wire up Component
	monitor.data_updated.connect(_on_data_updated)
	
	# 3. Start Monitoring
	# We pass the gradient definition to the monitor so it handles the math
	monitor.setup(
		vital_definition.type, 
		vital_definition.default_max_value, 
		vital_definition.gradient
	)

# --- VIEW LOGIC ---
func _on_data_updated(current: float, max_val: float, bar_color: Color) -> void:
	# Update Bar
	if vitals_progress_bar:
		vitals_progress_bar.max_value = max_val
		vitals_progress_bar.value = current
		vitals_progress_bar.tint_progress = bar_color

	# Update Text
	if vitals_label:
		vitals_label.text = "%s: %.0f/%.0f" % [vital_definition.display_name, current, max_val]
