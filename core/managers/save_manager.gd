extends Node

# REMOVED: const SAVE_PATH (We now generate this dynamically)
const AUTO_SAVE_INTERVAL = 30.0 

var _timer: Timer
var current_slot_id: int = 1 # Default to Slot 1

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.one_shot = false
	# CHANGED: Don't auto-start. We wait until a game actually starts/loads.
	_timer.autostart = false 
	_timer.timeout.connect(save_game)
	add_child(_timer)
	
	# REMOVED: load_game() 
	# We don't load automatically anymore; we wait for the Menu Button.

# NEW: Generates the path based on the Slot ID (e.g., "save_game_1.json")
func get_save_path(slot_id: int) -> String:
	return "user://save_game_" + str(slot_id) + ".json"

# NEW: Call this when starting a FRESH game to ensure the timer starts
func start_new_game(slot_id: int) -> void:
	current_slot_id = slot_id
	print("Starting new game on Slot ", slot_id)
	
	# Optional: Delete old save if it exists on this slot
	if save_file_exists(slot_id):
		delete_save(slot_id)
		
	# Start the auto-save timer
	_timer.start()

func save_game() -> void:
	print("Saving game to Slot ", current_slot_id, "...")
	
	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"currency": CurrencyManager.get_save_data(),
		"vitals": VitalManager.get_save_data(),
		"settings": SettingsManager.get_save_data(),
		"progression": ProgressionManager.get_save_data()
	}
	
	# Use the dynamic path for the current slot
	var path = get_save_path(current_slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		var json_text = JSON.stringify(save_data, "\t")
		file.store_string(json_text)
		file.close()

# UPDATED: Accepts an optional slot_id
func load_game(slot_id: int = -1) -> void:
	# If an ID is passed, update our current slot. Otherwise use current.
	if slot_id != -1:
		current_slot_id = slot_id

	var path = get_save_path(current_slot_id)
	
	if not FileAccess.file_exists(path):
		print("No save file found for Slot ", current_slot_id)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		print("Loading save from Slot ", current_slot_id, "...")
		
		if data.has("currency"): CurrencyManager.load_save_data(data.currency)
		if data.has("vitals") and VitalManager.has_method("load_save_data"): 
			VitalManager.load_save_data(data.vitals)
		if data.has("settings"): SettingsManager.load_save_data(data.settings)
		if data.has("progression"): ProgressionManager.load_save_data(data.progression)
		
		print("Game Loaded Successfully!")
		
		# Start the auto-save timer now that we are playing
		_timer.start()
	else:
		print("JSON Parse Error: ", json.get_error_message())

# UPDATED: Now requires an ID to know which file to delete
func delete_save(slot_id: int) -> void:
	var path = get_save_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Save slot ", slot_id, " deleted.")

# UPDATED: Check specific slot
func save_file_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot_id))

# Returns a dictionary with info about the slot:
# { "exists": bool, "timestamp": String }
func get_slot_metadata(slot_id: int) -> Dictionary:
	var path = get_save_path(slot_id)
	
	if not FileAccess.file_exists(path):
		return { "exists": false, "timestamp": "" }
	
	# Open file just to read the data
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		var time_str = ""
		
		# Convert Unix timestamp to readable date
		if data.has("timestamp"):
			var time_dict = Time.get_datetime_dict_from_unix_time(int(data.timestamp)) # Format: YYYY-MM-DD HH:MM
			time_str = "%04d-%02d-%02d %02d:%02d" % [time_dict.year, time_dict.month, time_dict.day, time_dict.hour, time_dict.minute]
			
		return { "exists": true, "timestamp": time_str }
		
	return { "exists": false, "timestamp": "Corrupted" }
