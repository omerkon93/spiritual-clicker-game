extends Control
class_name ShopMenu

signal panel_closed

# --- CONFIGURATION ---
@export var shop_button_scene: PackedScene

# Category Containers (Assign these in the Inspector to your GridContainers inside the Tabs)
@export_category("Grids")
@export var consumable_grid: GridContainer
@export var tools_grid: GridContainer
@export var technology_grid: GridContainer

@export_group("Settings")
@export var show_locked: bool = true
@export var show_purchased: bool = true # If false, hides items heavily (like one-time upgrades)

# --- LIFECYCLE ---
func _ready() -> void:
	# Connect to the new ProgressionManager signal
	ProgressionManager.upgrade_leveled_up.connect(_on_upgrade_event)
	
	# Optional: Listen for currency changes if you want to update button affordability in real-time
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

# --- POPULATION LOGIC ---
func _populate_shop() -> void:
	if not shop_button_scene: return
	
	# 1. Clear everything
	_clear_container(tools_grid)
	_clear_container(technology_grid)
	_clear_container(consumable_grid)
		
	# 2. Sort items into the correct grid
	# Note: We use ItemManager.available_items (renamed from available_upgrades)
	for item: LevelableUpgrade in ItemManager.available_items:
		
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
	# --- 1. STORY & FLAG CHECKS ---
	# Uses ProgressionManager for flags
	if item.required_story_flag != "" and not ProgressionManager.get_flag(item.required_story_flag):
		return 

	# --- 2. STATUS CHECKS ---
	var is_unlocked: bool = _check_requirements(item)
	# Uses ProgressionManager for levels
	var current_lvl: int = ProgressionManager.get_upgrade_level(item.id)
	var is_maxed: bool = (item.max_level != -1 and current_lvl >= item.max_level)
	
	# Feature: Hide superseded tools (e.g. Hide "Stone Axe" if "Iron Axe" is unlocked)
	if is_unlocked and not is_maxed and item.upgrade_type == LevelableUpgrade.UpgradeType.TOOL:
		if _is_superseded(item): return

	# --- 3. FILTER SETTINGS ---
	if not is_unlocked and not show_locked: return
	if is_maxed and not show_purchased: return

	# --- 4. SPAWN BUTTON ---
	var btn = shop_button_scene.instantiate()
	container.add_child(btn)
	
	# Pass the data to the button
	# Ensure your ShopItemButton script has a 'setup' function or 'upgrade_resource' setter
	if btn.has_method("setup"):
		btn.setup(item)
	elif "upgrade_resource" in btn:
		btn.upgrade_resource = item
	
	# --- 5. UI FEEDBACK ---
	# We handle the "Container" side of logic (hiding/disabling) here.
	# The Button script should handle the "Inner" logic (Name, Cost, Icon).
	
	if not is_unlocked:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 0.5) # Dimmed
		btn.tooltip_text = "Requirements not met"
	elif is_maxed:
		# Keep it visible but clearly finished
		btn.disabled = true
		btn.modulate = Color(0.5, 1.0, 0.5, 1.0) # Green tint
		btn.tooltip_text = "Max Level Reached"

func _clear_container(container: Container) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()

func _check_requirements(item: LevelableUpgrade) -> bool:
	if item.required_upgrade_id != "":
		# Check requirement against ProgressionManager
		var req_lvl = ProgressionManager.get_upgrade_level(item.required_upgrade_id)
		if req_lvl < item.required_level:
			return false
	return true

func _is_superseded(item: LevelableUpgrade) -> bool:
	# Check if a better version of this specific tool is already unlocked
	for other in ItemManager.available_items:
		# If another item requires THIS item, and that other item is unlocked...
		if other.required_upgrade_id == item.id and _check_requirements(other):
			# ...then THIS item is obsolete.
			return true
	return false
