extends Control
class_name ShopPanel

signal panel_closed

@export_category("Configuration")
#@export var shop_items: Array[LevelableUpgrade] = []
@export var button_scene: PackedScene

@export_category("Tab Containers")
@export var tools_grid: GridContainer 
@export var technology_grid: GridContainer
@export var consumable_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = true

@onready var close_button: Button = %CloseButton

func _ready() -> void:
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_event)
	if close_button:
		close_button.pressed.connect(close)

func open() -> void:
	visible = true
	_populate_shop()

func close() -> void:
	visible = false
	panel_closed.emit()

func _on_upgrade_event(_id: String, _lvl: int) -> void:
	if visible:
		_populate_shop()

func _populate_shop() -> void:
	if not button_scene: return
	
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
		
	# CHANGE: Loop through UpgradeManager's list instead of local array
	for item: LevelableUpgrade in UpgradeManager.available_upgrades:
		
		# ... (Rest of the logic remains exactly the same!) ...
		var target_container: Container = null
		
		match item.upgrade_type:
			LevelableUpgrade.UpgradeType.TOOL:
				target_container = tools_grid
			LevelableUpgrade.UpgradeType.TECHNOLOGY:
				target_container = technology_grid
			LevelableUpgrade.UpgradeType.CONSUMABLE:
				target_container = consumable_grid
			_:
				target_container = tools_grid

		if target_container:
			_process_item_for_container(item, target_container)

func _process_item_for_container(item: LevelableUpgrade, container: Container) -> void:
	# --- 1. VISIBILITY CHECK ---
	# Story Flag Check: If we haven't unlocked the story requirement, hide completely.
	if item.required_story_flag != "":
		if not GameStats.has_flag(item.required_story_flag):
			return 

	# --- 2. STATUS CHECKS ---
	var is_unlocked: bool = _check_requirements(item)
	var current_lvl: int = UpgradeManager.get_upgrade_level(item.id)
	var is_maxed: bool = (item.max_level != -1 and current_lvl >= item.max_level)
	
	var should_show: bool = false
	
	if is_unlocked:
		if not is_maxed:
			should_show = true
			# Hide obsolete tools (e.g. dont show "Stone Axe" if we have "Iron Axe")
			if item.upgrade_type == LevelableUpgrade.UpgradeType.TOOL and _is_superseded(item):
				should_show = false
		else:
			if show_purchased: should_show = true
	else:
		if show_locked: should_show = true

	# --- 3. CREATE BUTTON ---
	if should_show:
		var btn = button_scene.instantiate()
		
		# Assign data BEFORE adding to tree
		if "upgrade_resource" in btn:
			btn.upgrade_resource = item
			
		container.add_child(btn)
		
		# Visual States
		if not is_unlocked:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
			btn.disabled = true
			if item.required_upgrade_id != "":
				btn.tooltip_text = "Requires previous upgrade"
				
		elif is_maxed:
			btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
			btn.disabled = true
			# Optional: btn.text += " (MAX)"

func _clear_container(container: Container) -> void:
	if container:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

func _check_requirements(item: LevelableUpgrade) -> bool:
	# Check Tech Tree Logic
	if item.required_upgrade_id != "":
		var req_lvl: int = UpgradeManager.get_upgrade_level(item.required_upgrade_id)
		if req_lvl < item.required_level:
			return false
			
	# Double check story flag here (redundancy for safety)
	if item.required_story_flag != "":
		if not GameStats.has_flag(item.required_story_flag):
			return false
			
	return true

func _is_superseded(item_to_check: LevelableUpgrade) -> bool:
	for other_item in UpgradeManager.available_upgrades:
		
		if other_item.upgrade_type == item_to_check.upgrade_type:
			# If 'other_item' is the upgraded version of 'item_to_check'...
			if other_item.required_upgrade_id == item_to_check.id:
				
				# ...and that upgraded version is actually unlocked right now...
				if _check_requirements(other_item):
					return true
					
	return false
