extends Control
class_name ActionsMenu

# 1. SETTINGS
# The "Blueprint" button we created earlier
@export var action_button_scene: PackedScene

# The container where buttons will be organized
@export var grid_container: GridContainer

# Folder path to scan (Make sure this folder exists!)
const ACTIONS_PATH = "res://game_data/actions/"

func _ready() -> void:
	_populate_actions()

func _populate_actions() -> void:
	# Clear any dummy buttons you might have added in the editor
	for child in grid_container.get_children():
		child.queue_free()
	
	# Open the folder
	var dir = DirAccess.open(ACTIONS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Check if it's a valid resource file (.tres or .res)
			if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var data = load(ACTIONS_PATH + "/" + file_name)
				
				# Safety Check: Is this actually ActionData?
				if data is ActionData:
					_create_button(data)
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		printerr("ActionsPanel: Could not open path ", ACTIONS_PATH)

func _create_button(data: ActionData) -> void:
	# 1. Visibility Check
	if not data.is_visible_in_menu:
		return

	# 2. Existing Requirement Check
	if data.required_story_flag != "":
		if not GameStats.has_flag(data.required_story_flag):
			return 

	# 3. Spawn the Button (Existing Logic)
	var btn = action_button_scene.instantiate()
	grid_container.add_child(btn)
	btn.action_data = data
