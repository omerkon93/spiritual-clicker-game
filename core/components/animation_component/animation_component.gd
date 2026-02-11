extends Node
class_name AnimationComponent

# --- CONFIGURATION ---
@export var target_control: Control

# --- ANIMATION SETTINGS ---
@export_group("Shake Settings")
@export var shake_intensity: float = 5.0
@export var shake_duration: float = 0.05

@export_group("Bounce Settings")
@export var bounce_scale: Vector2 = Vector2(0.9, 0.9)
@export var bounce_duration: float = 0.05

@export_group("Floating Text Settings")
@export var random_offset_range: float = 20.0

# --- DEPENDENCIES ---
# (Assumes global SignalBus exists)

func _ready() -> void:
	# Default to the parent if not explicitly assigned
	if not target_control and get_parent() is Control:
		target_control = get_parent()

# ==============================================================================
# 1. SHAKE EFFECT (For Errors/Cost Failures)
# ==============================================================================
func play_shake(intensity_override: float = -1.0, duration_override: float = -1.0) -> void:
	if not target_control: return
	
	# 1. Identify what to shake (Preferably the icon or the internal container)
	# If the target is a Button, try to find its internal icon or just shake the pivot
	var shake_target = target_control
	
	# SAFEGUARD: If we are in a GridContainer, we CANNOT shake position.
	# Instead, we shake the "pivot_offset" which creates a similar visual effect 
	# without fighting the GridContainer's position logic.
	
	var final_intensity = shake_intensity if intensity_override < 0 else intensity_override
	var final_duration = shake_duration if duration_override < 0 else duration_override
	
	var original_offset = shake_target.pivot_offset.x
	var tween = create_tween()
	
	# Shake the PIVOT instead of the POSITION
	tween.tween_property(shake_target, "pivot_offset:x", original_offset - final_intensity, final_duration)
	tween.tween_property(shake_target, "pivot_offset:x", original_offset + final_intensity, final_duration)
	tween.tween_property(shake_target, "pivot_offset:x", original_offset, final_duration)
	
# ==============================================================================
# 2. BOUNCE EFFECT (For Clicks/Success)
# ==============================================================================
func play_bounce(scale_override: Vector2 = Vector2.ZERO, duration_override: float = -1.0) -> void:
	if not target_control: return
	
	# Use overrides if provided, otherwise use Inspector defaults
	var final_scale = bounce_scale if scale_override == Vector2.ZERO else scale_override
	var final_duration = bounce_duration if duration_override < 0 else duration_override
	
	# TRICK: If we are a button, try to bounce the ICON instead of the whole button.
	# This prevents the GridContainer from jittering.
	var bounce_target = target_control
	if target_control is Button and target_control.icon:
		# Try to find the internal texture rect or just use the button
		# (Simpler: just animate the button's icon scale if you made it a separate node)
		pass

	# Standard Pivot Logic
	bounce_target.pivot_offset = bounce_target.size / 2
	
	var tween = create_tween()
	# Scale Down -> Scale Back Up (Pop effect)
	tween.tween_property(bounce_target, "scale", final_scale, final_duration * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bounce_target, "scale", Vector2.ONE, final_duration * 0.5).set_trans(Tween.TRANS_BOUNCE)
	
# ==============================================================================
# 3. FLOATING TEXT (Feedback)
# ==============================================================================
func visualize_feedback(events: Array[Dictionary]) -> void:
	for event in events:
		spawn_floating_text(event.get("text", ""), event.get("color", Color.WHITE))

func spawn_floating_text(text: String, color: Color) -> void:
	# Get global mouse position for the text spawn point
	var pos = target_control.get_global_mouse_position()
	
	# Add slight randomness using the exported range
	pos.x += randf_range(-random_offset_range, random_offset_range)
	pos.y += randf_range(-random_offset_range, random_offset_range)
	
	# Send to the global manager (via SignalBus)
	SignalBus.request_floating_text.emit(pos, text, color)
