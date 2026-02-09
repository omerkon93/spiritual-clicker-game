extends Button

# The Setter ensures UI updates whenever data changes
@export var upgrade_resource: LevelableUpgrade :
	set(value):
		upgrade_resource = value
		if is_inside_tree():
			_update_label()
			_update_display()

# Visual colors
var color_affordable: Color = Color.WHITE
var color_expensive: Color = Color(1, 0.4, 0.4) 

func _ready():
	pressed.connect(_on_pressed)
	UpgradeManager.upgrade_leveled_up.connect(_on_level_changed)
	
	# --- LAYOUT SETTINGS ---
	expand_icon = true
	add_theme_constant_override("icon_max_width", 40)
	
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# FIX: Set X to 240 (Minimum Width), Keep Y at 0 (Auto Height)
	# This prevents the button from collapsing into a thin strip.
	custom_minimum_size = Vector2(240, 0) 
	
	# Helper: Tell the layout system to expand this button to fill the grid cell
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Text Wrapping
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	_update_label()
	_update_display()

func _process(_delta: float) -> void:
	if disabled or upgrade_resource == null:
		return

	# Real-time Affordability Check
	var cost = UpgradeManager.get_current_cost(upgrade_resource)
	var can_afford = Bank.has_enough_currency(upgrade_resource.cost_currency, cost)
	
	if can_afford:
		modulate = color_affordable
	else:
		modulate = color_expensive

func _on_pressed():
	UpgradeManager.try_purchase_level(upgrade_resource)

func _on_level_changed(changed_id: String, _new_lvl: int):
	if upgrade_resource and upgrade_resource.id == changed_id:
		_update_label()
		_update_display()
		
		if upgrade_resource.audio_on_purchase:
			SoundManager.play_sfx(upgrade_resource.audio_on_purchase, 1.1, 0.05)

func _update_label():
	if upgrade_resource == null: 
		text = "Loading..."
		return
	
	var cost = UpgradeManager.get_current_cost(upgrade_resource)
	var current_lvl = UpgradeManager.get_upgrade_level(upgrade_resource.id)
	var cost_str = NumberFormatter.format_value(cost)
	
	# The \n (newline) combined with autowrap_mode will force the button to grow
	text = " %s\n Cost: %s" % [
		upgrade_resource.display_name, 
		cost_str
	]
	
	if current_lvl > 0:
		text = " %s (Lvl %d)\n Cost: %s" % [upgrade_resource.display_name, current_lvl, cost_str]

func _update_display():
	if not upgrade_resource: return
	if upgrade_resource.icon:
		icon = upgrade_resource.icon
