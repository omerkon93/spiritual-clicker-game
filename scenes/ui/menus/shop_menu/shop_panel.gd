extends Control
class_name ShopPanel

signal panel_closed

@export_category("Configuration")
# Drag all your 'Tech_*.tres' resources here
@export var shop_items: Array[LevelableUpgrade] = []
# Drag 'ShopButton.tscn' here
@export var button_scene: PackedScene

@export_group("Filter Settings")
# For a Tech Shop, ensure this is set to TECH in the Inspector!
@export var filter_by_type: LevelableUpgrade.UpgradeType = LevelableUpgrade.UpgradeType.TECHNOLOGY
# Tech Tree Mode: Show items we can't buy yet? (Usually TRUE for Tech Trees)
@export var show_locked: bool = true
# Tech Tree Mode: Keep items visible after maxing? (Usually TRUE for Tech Trees)
@export var show_purchased: bool = true

@onready var container: Container = $MarginContainer/ScrollContainer/UpgradeContainer
@onready var close_button: Button = $CloseButton

func _ready() -> void:
	# Refresh UI whenever any upgrade happens (money changes, requirements met, etc)
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_event)
	
	if close_button:
		close_button.pressed.connect(close)
	
	# Start hidden?
	# visible = false 

func open() -> void:
	visible = true
	_populate_shop() # Force refresh to check new requirements

func close() -> void:
	visible = false
	# Emit this so other systems know the player closed it manually
	panel_closed.emit()

func _on_upgrade_event(_id: String, _lvl: int) -> void:
	if visible:
		_populate_shop()

func _populate_shop() -> void:
	if not button_scene or not container: return
		
	# 1. Clear existing buttons
	for child in container.get_children():
		child.queue_free()
		
	# 2. Loop through all items
	for item: LevelableUpgrade in shop_items:
		# --- FILTER 1: TYPE ---
		if item.upgrade_type != filter_by_type:
			continue

		# --- FILTER 2: STATUS ---
		var is_unlocked: bool = _check_requirements(item)
		var current_lvl: int = UpgradeManager.get_upgrade_level(item.id)
		var is_maxed: bool = (item.max_level != -1 and current_lvl >= item.max_level)
		
		var should_show: bool = false
		
		if is_unlocked:
			if not is_maxed:
				# Available to buy.
				should_show = true
				# Hide outdated tools (Only applies if this is a Tool shop)
				if item.upgrade_type == LevelableUpgrade.UpgradeType.TOOL and _is_superseded(item):
					should_show = false
			else:
				# Maxed out. Show if config says so.
				if show_purchased: should_show = true
		else:
			# Locked. Show if config says so.
			if show_locked: should_show = true

		# --- CREATE BUTTON ---
		if should_show:
			_create_button(item, is_unlocked, is_maxed)

func _check_requirements(item: LevelableUpgrade) -> bool:
	if item.required_upgrade_id == "":
		return true
	
	var req_lvl: int = UpgradeManager.get_upgrade_level(item.required_upgrade_id)
	return req_lvl >= item.required_level

func _is_superseded(item_to_check: LevelableUpgrade) -> bool:
	for other_item: LevelableUpgrade in shop_items:
		if other_item.upgrade_type == filter_by_type and _check_requirements(other_item):
			# If a better item requires the one we are checking, the one we are checking is old.
			if other_item.required_upgrade_id == item_to_check.id:
				return true
	return false

func _create_button(item: LevelableUpgrade, unlocked: bool, maxed: bool) -> void:
	var btn = button_scene.instantiate()
	
	# Duck-typing: Check if the button script has the variable before assigning
	if "upgrade_resource" in btn:
		btn.upgrade_resource = item
		
	container.add_child(btn)
	
	# --- VISUAL STATES ---
	if not unlocked:
		# TECH TREE LOCKED LOOK (Gray + Opacity)
		btn.modulate = Color(0.6, 0.6, 0.6, 0.5) 
		btn.disabled = true
		# Optional: Add a lock icon if your button supports it
		if btn.has_method("set_locked_visuals"):
			btn.set_locked_visuals(true)
			
	elif maxed:
		# TECH TREE OWNED LOOK (Green/Gold)
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
		btn.disabled = true
		if btn.has_method("set_maxed_visuals"):
			btn.set_maxed_visuals(true)
