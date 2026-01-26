class_name ShopPanel extends Control

@export_category("Configuration")
@export var shop_items: Array[LevelableUpgrade] = []
@export var button_scene: PackedScene

@export_group("Filter Settings")
# Filter: Only show items of this specific type
@export var filter_by_type: LevelableUpgrade.UpgradeType = LevelableUpgrade.UpgradeType.TOOL
# Tech Tree Mode: Show items we can't buy yet? (Grayed out)
@export var show_locked: bool = false
# Tech Tree Mode: Keep items visible after we max them out? (Green/Owned)
@export var show_purchased: bool = false

@onready var container: VBoxContainer = $MarginContainer/ScrollContainer/UpgradeContainer
@onready var close_button: Button = $CloseButton

func _ready():
	_populate_shop()
	# Refresh UI whenever an upgrade happens
	UpgradeManager.upgrade_leveled_up.connect(func(_id, _lvl): _populate_shop())
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _populate_shop():
	if not button_scene: return
		
	# 1. Clear existing buttons
	for child in container.get_children():
		child.queue_free()
		
	# 2. Loop through all items and decide what to show
	for item in shop_items:
		# --- FILTER 1: TYPE ---
		if item.upgrade_type != filter_by_type:
			continue

		# --- FILTER 2: STATUS ---
		var is_unlocked = _check_requirements(item)
		var current_lvl = UpgradeManager.get_upgrade_level(item.id)
		# Check if maxed (If max_level is -1, it's never maxed)
		var is_maxed = (item.max_level != -1 and current_lvl >= item.max_level)
		
		var should_show = false
		
		if is_unlocked:
			# It is unlocked. Should we show it?
			if not is_maxed:
				# It's available to buy. SHOW IT.
				should_show = true
				
				# ...UNLESS it's a Tool and a better Tool exists (Superseded)
				if item.upgrade_type == LevelableUpgrade.UpgradeType.TOOL:
					if _is_superseded(item):
						should_show = false
			else:
				# It is Maxed. Only show if "Show Purchased" is ON (Tech Tree mode).
				if show_purchased:
					should_show = true
		else:
			# It is Locked. Only show if "Show Locked" is ON (Tech Tree mode).
			if show_locked:
				should_show = true

		# --- CREATE BUTTON ---
		if should_show:
			_create_button(item, is_unlocked, is_maxed)

# Helper: Check if we meet requirements
func _check_requirements(item: LevelableUpgrade) -> bool:
	if item.required_upgrade_id == "":
		return true
	
	var req_lvl = UpgradeManager.get_upgrade_level(item.required_upgrade_id)
	return req_lvl >= item.required_level

# Helper: Check if a better tool is already unlocked (Hides old tools)
func _is_superseded(item_to_check: LevelableUpgrade) -> bool:
	for other_item in shop_items:
		# We only care about items of the same type that are unlocked
		if other_item.upgrade_type == filter_by_type and _check_requirements(other_item):
			# If the "Other Item" requires "Item To Check", then "Item To Check" is old news.
			if other_item.required_upgrade_id == item_to_check.id:
				return true
	return false

func _create_button(item: LevelableUpgrade, unlocked: bool, maxed: bool):
	var btn = button_scene.instantiate()
	
	# Pass data
	if "upgrade_resource" in btn:
		btn.upgrade_resource = item
		
	container.add_child(btn)
	
	# --- VISUAL FEEDBACK ---
	# We modify the button appearance based on state
	if not unlocked:
		# LOCKED STATE (Grayed out)
		btn.modulate = Color(0.5, 0.5, 0.5, 0.8) 
		btn.disabled = true
		btn.tooltip_text = "Requires: " + item.required_upgrade_id
		
	elif maxed:
		# OWNED STATE (Green tint)
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
		btn.disabled = true

func _on_close_pressed():
	# Simply hide this panel
	visible = false
