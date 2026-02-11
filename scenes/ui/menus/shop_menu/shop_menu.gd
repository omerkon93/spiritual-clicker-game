extends Control
class_name ShopMenu

signal panel_closed

# --- CONFIGURATION ---
@export var button_scene: PackedScene

# We export the GRIDS, not the tabs. 
# The TabContainer handles the tabs; we just need to know where to put buttons.
@export_category("Grids")
@export var consumable_grid: GridContainer
@export var tools_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = true

@onready var close_button: Button = %CloseButton
@onready var tab_container: TabContainer = %TabContainer

func _ready() -> void:
	# CRITICAL: Wait for Managers to finish their auto-scan
	await get_tree().process_frame
	
	# 1. Listen for data changes
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_event)
	visibility_changed.connect(_on_visibility_changed)
	
	# 2. Populate (now that data is safe)
	if visible:
		_populate_shop()

func open() -> void:
	_populate_shop()

func close() -> void:
	panel_closed.emit()

# This runs automatically whenever you click the Shop Tab
func _on_visibility_changed() -> void:
	if visible:
		_populate_shop()

func _on_upgrade_event(_id: String, _lvl: int) -> void:
	if visible:
		_populate_shop()

func _populate_shop() -> void:
	if not button_scene: return
	
	# 1. Clear everything
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
		
	# 2. Sort items into the correct grid
	for item: LevelableUpgrade in UpgradeManager.available_upgrades:
		
		var target_container: Container = null
		
		match item.upgrade_type:
			LevelableUpgrade.UpgradeType.TOOL:
				target_container = tools_grid
			LevelableUpgrade.UpgradeType.TECHNOLOGY:
				target_container = technology_grid
			LevelableUpgrade.UpgradeType.CONSUMABLE:
				target_container = consumable_grid
			_:
				target_container = tools_grid # Default fallback

		if target_container:
			_process_item_for_container(item, target_container)

func _process_item_for_container(item: LevelableUpgrade, container: Container) -> void:
	# --- VISIBILITY LOGIC ---
	if item.required_story_flag != "" and not GameStatsManager.has_flag(item.required_story_flag):
		return 

	var is_unlocked: bool = _check_requirements(item)
	var current_lvl: int = UpgradeManager.get_upgrade_level(item.id)
	var is_maxed: bool = (item.max_level != -1 and current_lvl >= item.max_level)
	
	# Hide outdated tools (e.g., Don't show Stone Pickaxe if you have Iron)
	if is_unlocked and not is_maxed and item.upgrade_type == LevelableUpgrade.UpgradeType.TOOL:
		if _is_superseded(item): return

	# User Preference Checks
	if not is_unlocked and not show_locked: return
	if is_maxed and not show_purchased: return

	# --- SPAWN BUTTON ---
	var btn = button_scene.instantiate() as ShopItemButton
	container.add_child(btn)
	
	# The Button Script handles its own label updates via this setter
	btn.upgrade_resource = item
	
	# --- LOCK STATE ---
	if not is_unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
		btn.tooltip_text = "Requirements not met"
	elif is_maxed:
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0) # Green tint for maxed
		btn.text += " (MAX)"

func _clear_container(container: Container) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()

func _check_requirements(item: LevelableUpgrade) -> bool:
	if item.required_upgrade_id != "":
		var req_lvl = UpgradeManager.get_upgrade_level(item.required_upgrade_id)
		if req_lvl < item.required_level:
			return false
	return true

func _is_superseded(item: LevelableUpgrade) -> bool:
	# Check if a better version of this specific tool is already unlocked
	for other in UpgradeManager.available_upgrades:
		if other.required_upgrade_id == item.id and _check_requirements(other):
			return true
	return false
