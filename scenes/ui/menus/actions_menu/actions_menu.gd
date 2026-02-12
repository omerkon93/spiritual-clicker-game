extends Control
class_name ActionsMenu

# --- CONFIGURATION ---
@export var action_button_scene: PackedScene

@export_category("Grids")
@export var career_grid: GridContainer
@export var survival_grid: GridContainer
@export var spiritual_grid: GridContainer

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	ProgressionManager.flag_changed.connect(_on_flag_changed)
	if visible:
		_populate_menu()


func _on_visibility_changed() -> void:
	if visible:
		_populate_menu()

func _on_flag_changed(_id: String, _val: bool) -> void:
	if visible:
		_populate_menu()

func _populate_menu() -> void:
	if not action_button_scene: return
	
	_clear_all_grids()
		
	for action in ActionManager.all_actions:
		# 1. VISIBILITY CHECK (Basic)
		if not action.is_visible_in_menu: 
			continue

		# 2. PROGRESSION CHECK (The Fix)
		# We check if the Resource is assigned (not null)
		# Then we ask ProgressionManager if we have it.
		if action.required_story_flag != null:
			if not ProgressionManager.get_flag(action.required_story_flag):
				continue
		
		# 3. SORTING
		var target_grid = _get_grid_for_category(action.category)
		if target_grid:
			_create_action_button(action, target_grid)

func _get_grid_for_category(category: ActionData.ActionCategory) -> GridContainer:
	match category:
		ActionData.ActionCategory.CAREER: return career_grid
		ActionData.ActionCategory.SURVIVAL: return survival_grid
		ActionData.ActionCategory.SPIRITUAL: return spiritual_grid
	return career_grid

func _create_action_button(data: ActionData, container: GridContainer) -> void:
	var btn = action_button_scene.instantiate() as ActionButton
	container.add_child(btn)
	btn.action_data = data

func _clear_all_grids() -> void:
	_clear_container(career_grid)
	_clear_container(survival_grid)
	_clear_container(spiritual_grid)

func _clear_container(container: Container) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()
