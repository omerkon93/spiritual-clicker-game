extends Control
class_name ShopMenu

@warning_ignore("unused_signal")
signal panel_closed

# ==============================================================================
# CONFIGURATION
# ==============================================================================
@export var shop_button_scene: PackedScene

@export_category("Grids")
@export var consumable_grid: GridContainer
@export var tools_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = false 

const NEW_INDICATOR: String = " (!)"

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# 1. Connect Signals (Data Changes)
	# Rebuild whenever levels, flags, or money changes
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _l): _rebuild_ui())
	ProgressionManager.flag_changed.connect(func(_id, _v): _rebuild_ui())
	CurrencyManager.currency_changed.connect(func(_t, _a): _rebuild_ui())
	
	# 2. Connect Visibility Signal
	# Ensure the shop is fresh whenever the player opens it
	visibility_changed.connect(func(): if visible: _rebuild_ui())
	
	# 3. Force Initial Build
	# Populates the lists immediately on game start, preventing empty grids
	_rebuild_ui()

# ==============================================================================
# UI BUILDING
# ==============================================================================
func _rebuild_ui() -> void:
	if not shop_button_scene: return
	
	# Clear old buttons
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
	
	# Sort items into their respective grids
	for item in ItemManager.available_items:
		var target_grid: Container = null
		
		match item.item_type:
			GameItem.ItemType.TOOL: 
				target_grid = tools_grid
			GameItem.ItemType.TECHNOLOGY: 
				target_grid = technology_grid
			GameItem.ItemType.CONSUMABLE: 
				target_grid = consumable_grid
		
		if target_grid:
			_try_add_item_button(item, target_grid)

	_update_tab_titles()

func _try_add_item_button(item: GameItem, container: Container) -> void:
	# 1. Story Flag Check
	if item.required_story_flag and not ProgressionManager.get_flag(item.required_story_flag):
		return
	
	# 2. Unlock & Level Check
	var is_unlocked = _check_requirements(item)
	var current_lvl = ProgressionManager.get_upgrade_level(item.id)
	var is_maxed = (item.max_level != -1 and current_lvl >= item.max_level)
	
	# 3. Filter Visibility
	if not is_unlocked and not show_locked: return
	if is_maxed and not show_purchased: return

	# 4. Instantiate & Configure
	var btn = shop_button_scene.instantiate()
	container.add_child(btn)
	btn.upgrade_resource = item # This triggers the setter in ShopItemButton
	
	# 5. Set Visual State
	if not is_unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.5) # Dimmed
		var req_name = item.required_item.display_name if item.required_item else "Unknown"
		btn.tooltip_text = "Requires: %s" % req_name
	elif is_maxed:
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0) # Greenish tint
		btn.tooltip_text = "Max Level Reached"

# ==============================================================================
# TAB MANAGEMENT
# ==============================================================================
func _update_tab_titles() -> void:
	# Check if grids have children to decide if tabs should be shown
	_apply_tab_state(tools_grid, tools_grid.get_child_count() > 0)
	_apply_tab_state(technology_grid, technology_grid.get_child_count() > 0)
	_apply_tab_state(consumable_grid, consumable_grid.get_child_count() > 0)

func _apply_tab_state(grid: Control, has_items: bool) -> void:
	if not grid: return
	
	# Traverse up to find the TabContainer
	var parent = grid.get_parent()
	while parent and not (parent is TabContainer):
		parent = parent.get_parent()
		
	if parent is TabContainer:
		# Find the direct child of the TabContainer that holds this grid
		var tab_page = grid
		while tab_page.get_parent() != parent:
			tab_page = tab_page.get_parent()
			
		var idx = parent.get_tab_idx_from_control(tab_page)
		if idx != -1:
			parent.set_tab_hidden(idx, not has_items)

# ==============================================================================
# HELPERS
# ==============================================================================
func _clear_container(c: Container) -> void:
	if c:
		for child in c.get_children():
			child.queue_free()

func _check_requirements(i: GameItem) -> bool:
	if i.required_item == null: return true
	return ProgressionManager.get_upgrade_level(i.required_item.id) >= 1
