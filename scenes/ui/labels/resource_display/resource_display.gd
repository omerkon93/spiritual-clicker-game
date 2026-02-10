extends PanelContainer
class_name ResourceDisplay

# --- CONFIGURATION ---
# Accepts EITHER CurrencyDefinition OR VitalDefinition
@export var resource_def: Resource 

# --- NODES ---
@onready var icon_rect: TextureRect = $HBoxContainer/Icon
@onready var value_label: Label = $HBoxContainer/VBoxContainer/ValueLabel
@onready var progress_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar

# --- STATE ---
var _displayed_value: float = 0.0
var _is_vital: bool = false
var _id: int = -1

func _ready() -> void:
	if not resource_def:
		push_error("ResourceDisplay: No Resource assigned!")
		return

	# --- CRITICAL FIX: DISCONNECT FROM SHARED STYLE ---
	# Instead of getting the existing (shared) style, we make a NEW one.
	var unique_style = StyleBoxFlat.new()
	
	# Apply this NEW, UNIQUE style to this specific node
	progress_bar.add_theme_stylebox_override("fill", unique_style)
	
	# When you set the texture/logic later, it uses 'unique_style' automatically
	if resource_def is VitalDefinition:
		_setup_vital(resource_def)
	elif resource_def is CurrencyDefinition:
		_setup_currency(resource_def)

func _setup_currency(def: CurrencyDefinition) -> void:
	_is_vital = false
	_id = def.type
	
	# Visuals
	icon_rect.texture = def.icon
	progress_bar.visible = false # Money usually doesn't need a bar
	
	# Connect to Bank
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	# Initial Value
	var current = CurrencyManager.get_currency_amount(_id)
	_update_display(current, -1, false)

func _setup_vital(def: VitalDefinition) -> void:
	_is_vital = true
	_id = def.type
	
	# Visuals
	icon_rect.texture = def.icon
	progress_bar.visible = true
	
	# Connect to Vitals
	VitalManager.vital_changed.connect(_on_vital_changed)
	
	# Initial Value
	var current = VitalManager.get_current(_id)
	var max_v = VitalManager.get_max(_id)
	_update_display(current, max_v, false)

# --- EVENT HANDLERS ---
func _on_currency_changed(type: int, amount: float) -> void:
	if type == _id:
		_update_display(amount, -1)

func _on_vital_changed(type: int, current: float, max_val: float) -> void:
	if type == _id:
		_update_display(current, max_val)

# --- DISPLAY LOGIC ---
func _update_display(current: float, max_val: float, animate: bool = true) -> void:
	# Tween the Value Number
	if animate:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_method(_set_displayed_value, _displayed_value, current, 0.5)
		
		# Tween the Bar (Only for Vitals)
		if _is_vital and max_val > 0:
			var percent = (current / max_val) * 100.0
			tween.parallel().tween_property(progress_bar, "value", percent, 0.5)
			_update_gradient_color(percent) # Update color based on fullness
	else:
		_set_displayed_value(current)
		if _is_vital and max_val > 0:
			var percent = (current / max_val) * 100.0
			progress_bar.value = percent
			_update_gradient_color(percent)

func _set_displayed_value(val: float) -> void:
	_displayed_value = val
	
	if _is_vital:
		# Format: "Energy: 50/100"
		var max_v = VitalManager.get_max(_id)
		value_label.text = "%s: %d/%d" % [resource_def.display_name, int(val), int(max_v)]
	else:
		# Format: "Gold: $500"
		value_label.text = "%s: $%d" % [resource_def.display_name, int(val)]

func _update_gradient_color(percent: float) -> void:
	if not (resource_def is VitalDefinition) or not resource_def.gradient:
		return

	# 1. Get the color from the Gradient Resource
	# (Make sure your .tres file uses "Gradient", not "GradientTexture1D" for cleaner code)
	# If you stuck with Texture, use: resource_def.gradient.gradient.sample(percent / 100.0)
	var color = resource_def.gradient.sample(percent / 100.0)
	
	# 2. Grab the UNIQUE style we created in _ready()
	# "get_theme_stylebox" prioritizes the override we just set!
	var style = progress_bar.get_theme_stylebox("fill")
	
	# 3. Apply Color
	if style is StyleBoxFlat:
		style.bg_color = color
