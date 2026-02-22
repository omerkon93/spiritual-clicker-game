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
	var unique_style = StyleBoxFlat.new()
	progress_bar.add_theme_stylebox_override("fill", unique_style)
	
	if resource_def is VitalDefinition:
		_setup_vital(resource_def)
	elif resource_def is CurrencyDefinition:
		_setup_currency(resource_def)

func _setup_currency(def: CurrencyDefinition) -> void:
	_is_vital = false
	_id = def.type
	
	# Visuals
	if def.icon: icon_rect.texture = def.icon
	progress_bar.visible = false 
	
	# Apply the resource's custom color to the text!
	value_label.add_theme_color_override("font_color", def.display_color)
	
	# Connect to Bank
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	# Initial Value
	var current = CurrencyManager.get_currency_amount(_id)
	_update_display(current, -1, false)

func _setup_vital(def: VitalDefinition) -> void:
	_is_vital = true
	_id = def.type
	
	# Visuals
	if def.icon: icon_rect.texture = def.icon
	progress_bar.visible = true
	
	# Apply the resource's custom color to the text!
	value_label.add_theme_color_override("font_color", def.display_color)
	
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
			_update_gradient_color(percent) 
	else:
		_set_displayed_value(current)
		if _is_vital and max_val > 0:
			var percent = (current / max_val) * 100.0
			progress_bar.value = percent
			_update_gradient_color(percent)

func _set_displayed_value(val: float) -> void:
	_displayed_value = val
	
	if _is_vital:
		var def: VitalDefinition = resource_def
		var max_v = VitalManager.get_max(_id)
		# NEW Format: "⚡ Energy: 50/100"
		value_label.text = "%s %s: %d/%d" % [def.text_icon, def.display_name, int(val), int(max_v)]
	else:
		var def: CurrencyDefinition = resource_def
		# Format: "$ Money: 500" or "Money: $500" depending on how you want it
		value_label.text = "%s %s: %d" % [def.text_icon, def.display_name, int(val)]
func _update_gradient_color(percent: float) -> void:
	if not (resource_def is VitalDefinition) or not resource_def.gradient:
		return

	var color = resource_def.gradient.sample(percent / 100.0)
	var style = progress_bar.get_theme_stylebox("fill")
	
	if style is StyleBoxFlat:
		style.bg_color = color
