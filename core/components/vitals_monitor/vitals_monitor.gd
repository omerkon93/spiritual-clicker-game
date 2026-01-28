extends Node
class_name VitalMonitor

# --- SIGNALS ---
# We pass the calculated color so the View doesn't need to know about Gradients
signal data_updated(current: float, max_val: float, bar_color: Color)

# --- STATE ---
var vital_type: int = GameEnums.VitalType.NONE
var gradient: GradientTexture1D # We hold the gradient logic here

# --- SETUP ---
func setup(type: int, default_max: float, grad_texture: GradientTexture1D) -> void:
	vital_type = type
	gradient = grad_texture
	
	# 1. Connect
	if not VitalManager.vital_changed.is_connected(_on_vital_changed):
		VitalManager.vital_changed.connect(_on_vital_changed)
	
	# 2. Initial Fetch
	var current: float = VitalManager.get_current(vital_type)
	var max_val: float = VitalManager.get_max(vital_type)
	
	if max_val == 0: 
		max_val = default_max
		
	_process_update(current, max_val)

# --- LOGIC ---
func _on_vital_changed(type: int, current: float, max_val: float) -> void:
	if type == vital_type:
		_process_update(current, max_val)

func _process_update(current: float, max_val: float) -> void:
	# Calculate Color Logic
	var color: Color = Color.WHITE
	
	if gradient and gradient.gradient:
		var percent: float = 0.0
		if max_val > 0: 
			percent = current / max_val
		color = gradient.gradient.sample(percent)
	
	# Emit everything the UI needs
	data_updated.emit(current, max_val, color)
