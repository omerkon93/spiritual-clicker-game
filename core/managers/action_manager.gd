extends Node

# --- CONFIGURATION ---
# The folder where all your ActionData resources are stored
const AUTO_LOAD_PATHS = [
	"res://game_data/actions/player_actions/"
]

# --- STATE ---
# The master list used by the ActionsMenu to populate the UI
var all_actions: Array[ActionData] = []

# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Run the scanner as soon as the manager enters the tree
	_scan_for_actions()


# ==============================================================================
# 2. AUTO-LOADER LOGIC
# ==============================================================================
func _scan_for_actions() -> void:
	for path in AUTO_LOAD_PATHS:
		_load_dir_recursive(path)
	
	print("🎬 ActionManager: Automatically loaded %d actions." % all_actions.size())

func _load_dir_recursive(path: String) -> void:
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Dive into subfolders (e.g., res://game_data/actions/career/)
				if file_name != "." and file_name != "..":
					_load_dir_recursive(path + "/" + file_name)
			else:
				# Only load valid Godot resource files
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var full_path = path + "/" + file_name
					var resource = load(full_path)
					
					# Ensure the file is actually an ActionData resource
					if resource is ActionData:
						_add_action(resource)
			
			file_name = dir.get_next()
	else:
		print("❌ ActionManager Error: Could not open path: ", path)

func _add_action(action: ActionData) -> void:
	# Check for duplicates
	if not all_actions.any(func(x): return x.id == action.id):
		all_actions.append(action)
	else:
		# ADD THIS WARNING!
		push_warning("⚠️ ActionManager: Duplicate Action ID found! Skipped '%s' (ID: %s)" % [action.resource_path, action.id])


# ==============================================================================
# 3. PUBLIC API
# ==============================================================================
func get_action_by_id(id: String) -> ActionData:
	for action in all_actions:
		if action.id == id:
			return action
	return null
