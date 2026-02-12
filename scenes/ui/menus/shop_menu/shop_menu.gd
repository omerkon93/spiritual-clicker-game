extends Control
class_name ShopMenu

signal panel_closed

# --- CONFIGURATION ---
@export var shop_button_scene: PackedScene

# Category Containers
@export_category("Grids")
@export var consumable_grid: GridContainer
@export var tools_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = true 

# --- LIFECYCLE ---
func _ready() -> void:
	# 1. Listen for Upgrades (to update costs/levels)
	ProgressionManager.upgrade_leveled_up.connect(_on_upgrade_event)
	
	# 2. Listen for Flags (NEW: to show/hide items unlocked by story)
	ProgressionManager.flag_changed.connect(_on_flag_changed)
	
	# 3. Listen for Money (Optional: to update affordability color real-time)
	CurrencyManager.currency_changed.connect(func(_t, _a): _populate_shop())
	
	_populate_shop()

func open() -> void:
	show()
	_populate_shop()

func close() -> void:
	hide()
	panel_closed.emit()

func _on_visibility_changed() -> void:
	if visible:
		_populate_shop()

func _on_upgrade_event(_id: String, _lvl: int) -> void:
	if visible:
		_populate_shop()

func _on_flag_changed(_id: String, _val: bool) -> void:
	if visible:
		_populate_shop()

# --- POPULATION LOGIC ---
func _populate_shop() -> void:
	if not shop_button_scene: return
	
	# 1. Clear everything
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
		
	# 2. Sort items into the correct grid
	for item: GameItem in ItemManager.available_items:
		
		var target_container: Container = null
		
		match item.item_type:
			GameItem.ItemType.TOOL:
				target_container = tools_grid
			GameItem.ItemType.TECHNOLOGY:
				target_container = technology_grid
			GameItem.ItemType.CONSUMABLE:
				target_container = consumable_grid
			_:
				target_container = tools_grid

		if target_container:
			_process_item_for_container(item, target_container)

func _process_item_for_container(item: GameItem, container: Container) -> void:
	# --- 1. STORY & FLAG CHECKS ---
	# NEW: Check against the StoryFlag Resource
	if item.required_story_flag != null:
		if not ProgressionManager.get_flag(item.required_story_flag):
			return

	# --- 2. STATUS CHECKS ---
	var is_unlocked: bool = _check_requirements(item)
	var current_lvl: int = ProgressionManager.get_upgrade_level(item.id)
	var is_maxed: bool = (item.max_level != -1 and current_lvl >= item.max_level)
	
	# Hide superseded tools
	if is_unlocked and not is_maxed and item.item_type == GameItem.ItemType.TOOL:
		if _is_superseded(item): return

	# --- 3. FILTER SETTINGS ---
	if not is_unlocked and not show_locked: return
	if is_maxed and not show_purchased: return

	# --- 4. SPAWN BUTTON ---
	var btn = shop_button_scene.instantiate()
	container.add_child(btn)
	
	if btn.has_method("setup"):
		btn.setup(item)
	elif "upgrade_resource" in btn:
		btn.upgrade_resource = item
	
	# --- 5. UI FEEDBACK ---
	if not is_unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
		btn.tooltip_text = "Requirements not met"
	elif is_maxed:
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
		btn.tooltip_text = "Max Level Reached"

func _clear_container(container: Container) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()

func _check_requirements(item: GameItem) -> bool:
	if item.required_item_id != "":
		var req_lvl = ProgressionManager.get_upgrade_level(item.required_item_id)
		if req_lvl < item.required_level:
			return false
	return true

func _is_superseded(item: GameItem) -> bool:
	for other in ItemManager.available_items:
		if other.required_item_id == item.id and _check_requirements(other):
			return true
	return false
