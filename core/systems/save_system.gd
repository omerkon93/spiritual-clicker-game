extends Node

const SAVE_PATH = "user://savegame.json"

func save_game():
	var save_data = {
		"money": Bank.get_currency_amount(GameEnums.CurrencyType.MONEY),
		"upgrades": UpgradeManager.upgrade_levels # This now saves the Dictionary of {"iron_pick": 5}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data)
		file.store_string(json_str)
		print("Game Saved!")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return
	
	var json_str = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	
	if parse_result != OK:
		printerr("JSON Parse Error: ", json.get_error_message())
		return
		
	var data = json.get_data()
	
	# 1. Restore Bank
	if "money" in data:
		# We silently set the wallet without triggering 'added' visual effects
		Bank._wallet[GameEnums.CurrencyType.MONEY] = data["money"]
		Bank.currency_changed.emit(GameEnums.CurrencyType.MONEY, data["money"])
		
	# 2. Restore Upgrades (THE FIX)
	if "upgrades" in data:
		var loaded_upgrades = data["upgrades"]
		
		# Clear current state first
		UpgradeManager.upgrade_levels.clear()
		
		# Iterate through the dictionary
		for id in loaded_upgrades:
			var level = loaded_upgrades[id]
			
			# Ensure the Key is a String before using it (Safety cast)
			var string_id = str(id)
			
			# Inject into Manager
			UpgradeManager.upgrade_levels[string_id] = level
			
			# Emit signal so UI updates (Buttons change text)
			UpgradeManager.upgrade_leveled_up.emit(string_id, level)

	print("Game Loaded!")

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
