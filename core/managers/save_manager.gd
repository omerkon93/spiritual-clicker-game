extends Node

const SAVE_PATH = "user://save_game.json"
const AUTO_SAVE_INTERVAL = 30.0 

var _timer: Timer

func _ready() -> void:
	# Setup Auto-Save
	_timer = Timer.new()
	_timer.wait_time = AUTO_SAVE_INTERVAL
	_timer.autostart = true
	_timer.timeout.connect(save_game)
	add_child(_timer)
	
	# Load automatically on startup
	load_game()

func save_game() -> void:
	print("Saving game...")
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"currency": CurrencyManager.get_save_data(),
		"vitals": VitalManager.get_save_data(),
		"upgrades": UpgradeManager.get_save_data(),
		"stats": GameStatsManager.get_save_data(),
		"settings": SettingsManager.get_save_data()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_text = JSON.stringify(save_data, "\t")
		file.store_string(json_text)
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(text)
	
	if error == OK:
		var data = json.data
		print("Loading save...")
		
		if data.has("currency"): CurrencyManager.load_save_data(data.currency)
		if data.has("vitals"): VitalManager.load_save_data(data.vitals)
		if data.has("upgrades"): UpgradeManager.load_save_data(data.upgrades)
		if data.has("stats"): GameStatsManager.load_save_data(data.stats)
		if data.has("settings"): SettingsManager.load_save_data(data.settings)
		
		print("Game Loaded Successfully!")
	else:
		print("JSON Parse Error: ", json.get_error_message())

func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	print("Save deleted.")

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
