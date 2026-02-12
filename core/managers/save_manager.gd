extends Node

const SAVE_PATH = "user://save_game.json"
const AUTO_SAVE_INTERVAL = 30.0 

var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(save_game)
	add_child(_timer)
	
	load_game()

func save_game() -> void:
	print("Saving game...")
	
	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"currency": CurrencyManager.get_save_data(),
		"vitals": VitalManager.get_save_data(),
		"settings": SettingsManager.get_save_data(),
		# Centralized Progression
		"progression": ProgressionManager.get_save_data()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(save_data, "\t")
		file.store_string(json_text)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found. Starting fresh.")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		print("Loading save...")
		
		# 1. Load Standard Managers
		if data.has("currency"): CurrencyManager.load_save_data(data.currency)
		if data.has("vitals") and VitalManager.has_method("load_save_data"): 
			VitalManager.load_save_data(data.vitals)
		if data.has("settings"): SettingsManager.load_save_data(data.settings)
		
		# 2. Load Progression
		# If the key is missing (old save), it simply skips loading progression
		# effectively resetting your upgrades/flags to 0 (Fresh Start behavior).
		if data.has("progression"):
			ProgressionManager.load_save_data(data.progression)
		
		print("Game Loaded Successfully!")
	else:
		print("JSON Parse Error: ", json.get_error_message())

func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	print("Save deleted.")

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
