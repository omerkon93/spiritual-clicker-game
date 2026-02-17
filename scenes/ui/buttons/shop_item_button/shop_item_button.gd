extends Button
class_name ShopItemButton

# The Setter ensures UI updates whenever data changes
@export var upgrade_resource: GameItem :
	set(value):
		upgrade_resource = value
		if is_node_ready(): 
			_update_label()
			_update_display()

# Visual colors
var color_affordable: Color = Color.WHITE
var color_expensive: Color = Color(1, 0.4, 0.4, 1.0)

# --- COMPONENT REFERENCES ---
@onready var notification_indicator_component: NotificationIndicatorComponent = $NotificationIndicatorComponent

func _ready() -> void:
	pressed.connect(_on_pressed)
	ProgressionManager.upgrade_leveled_up.connect(_on_level_changed)
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	# --- LAYOUT FIXES ---
	custom_minimum_size = Vector2(240, 60)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Ensure text wraps properly so it doesn't push the button off-screen
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# --- INITIALIZATION ---
	if upgrade_resource:
		_update_label()
		_update_display()
	else:
		text = "Loading..."

func _on_pressed() -> void:
	if not upgrade_resource: return
	
	if notification_indicator_component:
		notification_indicator_component.mark_as_seen()
	
	# Try the purchase
	ItemManager.try_purchase_item(upgrade_resource)
	
	# NEW: Force a label refresh immediately after clicking
	_update_label()
	
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
	var cost_str = NumberFormatter.format_value(cost)
	
	# --- HANDLE TEXT ---
	var name_text = upgrade_resource.display_name
	if current_lvl > 0:
		name_text += " (Lvl %d)" % current_lvl
	text = "%s\n$%s" % [name_text, cost_str]

	# --- HANDLE COLOR (Affordability) ---
	var can_afford = CurrencyManager.has_enough_currency(upgrade_resource.cost_currency, cost)
	modulate = color_affordable if can_afford else color_expensive

func _update_display() -> void:
	if not upgrade_resource: return
	if upgrade_resource.icon:
		icon = upgrade_resource.icon
	
	# --- NEW: CONFIGURE NOTIFICATION ---
	if notification_indicator_component:
		# We pass 'self' so the SHOP BUTTON blinks
		notification_indicator_component.configure(upgrade_resource.id, self)

func _on_currency_changed(_type: int, _new_amount: float) -> void:
	# Just calling update_label is enough to refresh everything
	_update_label()
