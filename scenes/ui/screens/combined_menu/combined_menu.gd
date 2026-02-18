extends Control
class_name CombinedMenu

# --- NODES ---
@onready var tab_container: TabContainer = %TabContainer

# Adjust paths to match your Scene Tree structure EXACTLY
@onready var actions_tab_node: ActionsMenu = %Actions
@onready var shop_tab_node: ShopMenu = %Shop

const NEW_INDICATOR: String = " (!)"

func _ready() -> void:
	# Listen for any data change that affects "New" status
	ProgressionManager.item_seen.connect(func(_id): _update_tabs())
	ProgressionManager.flag_changed.connect(func(_id, _val): _update_tabs())
	ProgressionManager.upgrade_leveled_up.connect(func(_id, _lvl): _update_tabs())
	
	_update_tabs()

func _on_visibility_changed() -> void:
	if visible:
		_update_tabs()

func _update_tabs() -> void:
	if not tab_container: return

	# 1. Update Actions Tab
	var new_actions = _has_new_content_in_actions()
	_set_tab_notification(actions_tab_node, new_actions)

	# 2. Update Shop Tab
	var new_shop = _has_new_content_in_shop()
	_set_tab_notification(shop_tab_node, new_shop)

func _set_tab_notification(tab_node: Control, is_new: bool) -> void:
	if not tab_node: return
	var idx = tab_container.get_tab_idx_from_control(tab_node)
	if idx == -1: return

	var title = tab_container.get_tab_title(idx).replace(NEW_INDICATOR, "")
	if is_new: title += NEW_INDICATOR
	tab_container.set_tab_title(idx, title)

# --- DATA CHECKERS ---
func _has_new_content_in_actions() -> bool:
	for action in ActionManager.all_actions:
		if ProgressionManager.is_item_new(action.id):
			if action.is_visible_in_menu:
				# NOTE: ActionData still has 'required_story_flag', so this is fine.
				if not action.required_story_flag or ProgressionManager.get_flag(action.required_story_flag):
					return true
	return false

func _has_new_content_in_shop() -> bool:
	for item in ItemManager.available_items:
		if ProgressionManager.is_item_new(item.id):
			
			# --- FIX START: Check Requirements Array ---
			var content_is_visible = true
			
			for req in item.requirements:
				# 1. Ignore Money/Resources (Costs shouldn't hide the item)
				if req is CurrencyRequirement:
					continue
				
				# 2. Check Hard Requirements (Story Flags, Prerequisites)
				# If a hard requirement isn't met, the item is hidden -> Not "New"
				if req.has_method("is_met") and not req.is_met():
					content_is_visible = false
					break
			
			if content_is_visible:
				return true
			# --- FIX END ---
			
	return false
