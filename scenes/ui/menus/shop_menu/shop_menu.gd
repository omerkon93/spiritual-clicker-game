extends Control
class_name ShopMenu

@warning_ignore("unused_signal")
signal panel_closed

# --- CONFIGURATION ---
@export var shop_button_scene: PackedScene

@export_category("Grids")
@export var consumable_grid: GridContainer
@export var tools_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = true 

const NEW_INDICATOR: String = " (!)"

func _ready() -> void:
	# Heavy Updates (Rebuild list)
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _l): _rebuild_ui())
	ProgressionManager.flag_changed.connect(func(_id, _v): _rebuild_ui())
	CurrencyManager.currency_changed.connect(func(_t, _a): _rebuild_ui())
	
	# Light Update (Just tabs)
	ProgressionManager.item_seen.connect(func(_id): _update_tab_titles())
	
	if visible: _rebuild_ui()

func _on_visibility_changed() -> void:
	if visible: _rebuild_ui()

# --- 1. HEAVY LIFTING ---
func _rebuild_ui() -> void:
	if not shop_button_scene: return
	
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
	
	for item in ItemManager.available_items:
		var target: Container = tools_grid
		match item.item_type:
			GameItem.ItemType.TECHNOLOGY: target = technology_grid
			GameItem.ItemType.CONSUMABLE: target = consumable_grid
		
		_try_add_item_button(item, target)

	_update_tab_titles()

# --- 2. LIGHTWEIGHT ---
func _update_tab_titles() -> void:
	# Check Tools
	var s_tools = _scan_category(GameItem.ItemType.TOOL)
	_apply_tab_state(tools_grid, s_tools.has_items, s_tools.has_new)
	
	# Check Tech
	var s_tech = _scan_category(GameItem.ItemType.TECHNOLOGY)
	_apply_tab_state(technology_grid, s_tech.has_items, s_tech.has_new)
	
	# Check Consumable
	var s_cons = _scan_category(GameItem.ItemType.CONSUMABLE)
	_apply_tab_state(consumable_grid, s_cons.has_items, s_cons.has_new)

# --- LOGIC ---
func _try_add_item_button(item: GameItem, container: Container) -> void:
	# Filter Logic
	if item.required_story_flag and not ProgressionManager.get_flag(item.required_story_flag): return
	
	var is_unlocked = _check_requirements(item)
	var lvl = ProgressionManager.get_upgrade_level(item.id)
	var is_maxed = (item.max_level != -1 and lvl >= item.max_level)
	
	if is_unlocked and not is_maxed and item.item_type == GameItem.ItemType.TOOL:
		if _is_superseded(item): return

	if not is_unlocked and not show_locked: return
	if is_maxed and not show_purchased: return

	# Instantiate
	if container:
		var btn = shop_button_scene.instantiate()
		container.add_child(btn)
		btn.upgrade_resource = item
		
		if not is_unlocked:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.5)
			btn.tooltip_text = "Requirements not met"
		elif is_maxed:
			btn.disabled = true
			btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
			btn.tooltip_text = "Max Level Reached"

func _scan_category(type: int) -> Dictionary:
	var has_items = false
	var has_new = false
	
	for item in ItemManager.available_items:
		if item.item_type != type and (type != GameItem.ItemType.TOOL or item.item_type != -1): 
			# Simple matching: if not exact match, and not catching default tools, skip
			if item.item_type != type: continue
			
		# Repeat Filter Logic purely for counting
		if item.required_story_flag and not ProgressionManager.get_flag(item.required_story_flag): continue
		
		var is_unlocked = _check_requirements(item)
		var lvl = ProgressionManager.get_upgrade_level(item.id)
		var is_maxed = (item.max_level != -1 and lvl >= item.max_level)
		
		if is_unlocked and not is_maxed and item.item_type == GameItem.ItemType.TOOL:
			if _is_superseded(item): continue
		if not is_unlocked and not show_locked: continue
		if is_maxed and not show_purchased: continue
		
		# Valid Item Found
		has_items = true
		if ProgressionManager.is_item_new(item.id):
			has_new = true
			
	return { "has_items": has_items, "has_new": has_new }
	
func _apply_tab_state(grid: Control, show_tab: bool, show_indicator: bool) -> void:
	if not grid: return
	
	# Start climbing from the grid
	var current_node = grid
	var parent_node = current_node.get_parent()
	
	while parent_node:
		if parent_node is TabContainer:
			var container = parent_node as TabContainer
			
			# FIX: 'current_node' is the node we just stepped up from.
			# It is guaranteed to be the direct child of the TabContainer.
			var idx = container.get_tab_idx_from_control(current_node)
			
			if idx != -1:
				# 1. Hide/Show
				container.set_tab_hidden(idx, not show_tab)
				
				# 2. Title Logic
				var title = container.get_tab_title(idx).replace(NEW_INDICATOR, "")
				if show_indicator: title += NEW_INDICATOR
				container.set_tab_title(idx, title)
			
			return # Found and handled
		
		# Climb up one level
		current_node = parent_node
		parent_node = current_node.get_parent()
		
		# Stop if we hit the script root or run out of parents
		if parent_node == self or parent_node == null: 
			return

# Helpers
func _clear_container(c): if c: for child in c.get_children(): child.queue_free()
func _check_requirements(i): return not (i.required_item and ProgressionManager.get_upgrade_level(i.required_item.id) < 1)
func _is_superseded(item):
	for o in ItemManager.available_items:
		if o.required_item and o.required_item.id == item.id and _check_requirements(o): return true
	return false
