extends Control
class_name CombinedMenu

# --- NODES ---
@onready var tab_container: TabContainer = %TabContainer
@onready var actions_tab_node: ActionsMenu = %Actions
@onready var shop_tab_node: ShopMenu = %Shop

const NEW_INDICATOR: String = " (!)"

func _ready() -> void:
	ProgressionManager.item_seen.connect(func(_id): _update_tabs())
	ProgressionManager.flag_changed.connect(func(_id, _val): _update_tabs())
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _lvl): _update_tabs())
	
	# NEW: Listen for tab clicks to clear the notifications
	if tab_container:
		tab_container.tab_changed.connect(_on_tab_changed)
	
	_update_tabs()

func _on_visibility_changed() -> void:
	if visible: _update_tabs()

func _update_tabs() -> void:
	if not tab_container: return
	_set_tab_notification(actions_tab_node, _has_new_content_in_actions())
	_set_tab_notification(shop_tab_node, _has_new_content_in_shop())

func _set_tab_notification(tab_node: Control, is_new: bool) -> void:
	if not tab_node: return
	var idx = tab_container.get_tab_idx_from_control(tab_node)
	if idx == -1: return

	var title = tab_container.get_tab_title(idx).replace(NEW_INDICATOR, "")
	if is_new: title += NEW_INDICATOR
	tab_container.set_tab_title(idx, title)

# --- CLEARING LOGIC ---
func _on_tab_changed(tab_idx: int) -> void:
	var current_tab = tab_container.get_tab_control(tab_idx)
	
	if current_tab == actions_tab_node:
		for action in ActionManager.all_actions:
			if ProgressionManager.is_item_new(action.id):
				ProgressionManager.mark_item_as_seen(action.id)
				
	elif current_tab == shop_tab_node:
		for item in ItemManager.available_items:
			if ProgressionManager.is_item_new(item.id):
				ProgressionManager.mark_item_as_seen(item.id)
	
	_update_tabs()

# --- DATA CHECKERS ---
func _has_new_content_in_actions() -> bool:
	for action in ActionManager.all_actions:
		if ProgressionManager.is_item_new(action.id) and action.is_visible_in_menu:
			if not action.required_story_flag or ProgressionManager.get_flag(action.required_story_flag):
				return true
	return false

func _has_new_content_in_shop() -> bool:
	for item in ItemManager.available_items:
		# FIXED: Only check items we haven't seen yet
		if not ProgressionManager.is_item_new(item.id):
			continue
			
		if ProgressionManager.get_upgrade_level(item.id) >= 1:
			continue
			
		# FIXED: Use the correct variable name (story_flags_unlock)
		var is_unlocked = true
		if "story_flags_unlock" in item:
			for flag in item.story_flags_unlock:
				if flag and not ProgressionManager.get_flag(flag.id):
					is_unlocked = false
					break
		
		if not is_unlocked: continue
			
		var can_afford = true
		
		# FIXED: Use currency_requirements dictionary
		if "currency_requirements" in item:
			for cur_def: CurrencyDefinition in item.currency_requirements:
				var amount = item.currency_requirements[cur_def]
				if not CurrencyManager.has_enough_currency(cur_def.type, amount):
					can_afford = false
					break
		
		if not can_afford: continue
		
		# FIXED: Use vital_requirements dictionary
		if "vital_requirements" in item:
			for vit_def: VitalDefinition in item.vital_requirements:
				var amount = item.vital_requirements[vit_def]
				if not VitalManager.has_enough(vit_def.type, amount):
					can_afford = false
					break
				
		if can_afford: return true
			
	return false
