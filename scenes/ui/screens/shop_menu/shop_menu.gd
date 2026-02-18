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
@export var upgrade_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = false 

const NEW_INDICATOR: String = " (!)"

# ==============================================================================
# LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# 1. Connect Signals
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _l): _rebuild_ui())
	ProgressionManager.flag_changed.connect(func(_id, _v): _rebuild_ui())
	CurrencyManager.currency_changed.connect(func(_t, _a): _rebuild_ui())
	
	visibility_changed.connect(func(): if visible: _rebuild_ui())
	
	_rebuild_ui()

# ==============================================================================
# UI BUILDING
# ==============================================================================
func _rebuild_ui() -> void:
	if not shop_button_scene: return
	
	_clear_container(upgrade_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
	
	for item in ItemManager.available_items:
		var target_grid: Container = null
		
		match item.item_type:
			GameItem.ItemType.UPGRADE: 
				target_grid = upgrade_grid
			GameItem.ItemType.TECHNOLOGY: 
				target_grid = technology_grid
			GameItem.ItemType.CONSUMABLE: 
				target_grid = consumable_grid
		
		if target_grid:
			_try_add_item_button(item, target_grid)

	_update_tab_titles()

func _try_add_item_button(item: GameItem, container: Container) -> void:
	# ----------------------------------------------------------------------
	# 1. DETERMINE UNLOCK STATUS
	# ----------------------------------------------------------------------
	# We check if all NON-MONEY requirements are met (e.g., Story Flags, Prereqs).
	var is_unlocked = true
	var locked_reason = "Requirements not met"
	
	for req in item.requirements:
		# We assume 'CurrencyRequirement' implies a cost, not a hard lock.
		# If you named your script differently, update this check.
		if req is CurrencyRequirement:
			continue
			
		# Check Story Flags or Item Prerequisites
		if req.has_method("is_met") and not req.is_met():
			is_unlocked = false
			# Try to get a helpful reason for the tooltip
			if req.has_method("get_display_text"):
				locked_reason = req.get_display_text()
			break
	
	# ----------------------------------------------------------------------
	# 2. DETERMINE OWNERSHIP (MAXED)
	# ----------------------------------------------------------------------
	# In the new system, Tools/Tech are "Owned" if level >= 1.
	var current_lvl = ProgressionManager.get_upgrade_level(item.id)
	var is_owned = false
	
	if item.item_type != GameItem.ItemType.CONSUMABLE:
		if current_lvl >= 1:
			is_owned = true

	# ----------------------------------------------------------------------
	# 3. FILTER VISIBILITY
	# ----------------------------------------------------------------------
	if not is_unlocked and not show_locked: return
	if is_owned and not show_purchased: return

	# ----------------------------------------------------------------------
	# 4. INSTANTIATE
	# ----------------------------------------------------------------------
	var btn = shop_button_scene.instantiate()
	container.add_child(btn)
	btn.upgrade_resource = item # Triggers the button's internal update logic
	
	# ----------------------------------------------------------------------
	# 5. APPLY VISUAL OVERRIDES
	# ----------------------------------------------------------------------
	if not is_unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.5) # Dimmed
		btn.tooltip_text = "Locked: %s" % locked_reason
	
	elif is_owned:
		# The button script handles text, but we can force state here too
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0) # Greenish
		btn.tooltip_text = "Owned"

# ==============================================================================
# TAB MANAGEMENT
# ==============================================================================
func _update_tab_titles() -> void:
	_apply_tab_state(upgrade_grid, upgrade_grid.get_child_count() > 0)
	_apply_tab_state(technology_grid, technology_grid.get_child_count() > 0)
	_apply_tab_state(consumable_grid, consumable_grid.get_child_count() > 0)

func _apply_tab_state(grid: Control, has_items: bool) -> void:
	if not grid: return
	
	var parent = grid.get_parent()
	while parent and not (parent is TabContainer):
		parent = parent.get_parent()
		
	if parent is TabContainer:
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
