@tool
extends EditorScript

func _run() -> void:
	# PATH TO YOUR ACTIONS FOLDER
	var folder_path = "res://game_data/actions/player_actions/"
	var script_path = "res://core/resources/action_data.gd" # Verify this path!
	
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Dive into subfolders (e.g., survival, career)
				if file_name != "." and file_name != "..":
					_fix_recursive(folder_path + "/" + file_name, script_path)
			else:
				if file_name.ends_with(".tres"):
					_fix_file(folder_path + "/" + file_name, script_path)
			
			file_name = dir.get_next()
		print("🎉 All Done! Reload the project now.")
	else:
		print("❌ Error: Could not find folder: " + folder_path)

func _fix_recursive(path: String, script_path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				_fix_file(path + "/" + file_name, script_path)
			file_name = dir.get_next()

func _fix_file(full_path: String, script_path: String) -> void:
	print("🔧 Fixing: " + full_path)
	
	# 1. Load the resource (even if generic)
	var res = load(full_path)
	if not res:
		print("   ⚠️ Could not load file!")
		return

	# 2. Force-assign the correct script
	var script_res = load(script_path)
	res.set_script(script_res)
	
	# 3. Save it back to disk
	ResourceSaver.save(res, full_path)
	print("   ✅ Saved!")
