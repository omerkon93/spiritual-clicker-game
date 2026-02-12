extends Button
class_name ShopItemButton

# The Setter ensures UI updates whenever data changes
@export var upgrade_resource: GameItem :
	set(value):
		upgrade_resource = value
		if is_inside_tree():
			_update_label()
			_update_display()

# Visual colors
var color_affordable: Color = Color.WHITE
var color_expensive: Color = Color(1, 0.4, 0.4) 

func _ready() -> void:
	pressed.connect(_on_pressed)
	
	# Correctly listen to ProgressionManager
	ProgressionManager.upgrade_leveled_up.connect(_on_level_changed)
	
	# --- LAYOUT SETTINGS ---
	expand_icon = true
	add_theme_constant_override("icon_max_width", 48)
	
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	custom_minimum_size = Vector2(240, 60) 
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	_update_label()
	_update_display()

func _process(_delta: float) -> void:
	if disabled or upgrade_resource == null:
		return

	var cost = ItemManager.get_current_cost(upgrade_resource)
	var can_afford = CurrencyManager.has_enough_currency(upgrade_resource.cost_currency, cost)
	
	if can_afford:
		modulate = color_affordable
	else:
		modulate = color_expensive

func _on_pressed() -> void:
	if not upgrade_resource: return
	
	ItemManager.try_purchase_item(upgrade_resource)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.05)

func _on_level_changed(changed_id: String, _new_lvl: int) -> void:
	if upgrade_resource and upgrade_resource.id == changed_id:
		_update_label()
		_update_display()

func _update_label() -> void:
	if upgrade_resource == null: 
		text = "Loading..."
		return
	
	var cost = ItemManager.get_current_cost(upgrade_resource)
	var current_lvl = ProgressionManager.get_upgrade_level(upgrade_resource.id)
	
	# Static call to NumberFormatter
	var cost_str = NumberFormatter.format_value(cost)
	
	var name_text = upgrade_resource.display_name
	if current_lvl > 0:
		name_text += " (Lvl %d)" % current_lvl
		
	text = "%s\n$%s" % [name_text, cost_str]

func _update_display() -> void:
	if not upgrade_resource: return
	if upgrade_resource.icon:
		icon = upgrade_resource.icon
