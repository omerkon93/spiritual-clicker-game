extends Node

const SAVE_PATH = "user://savegame.json"

func save_game() -> void:
	var save_data = {
		# 1. CURRENCY
		"money": CurrencyManager.get_currency_amount(GameEnums.CurrencyType.MONEY),
		"spirit": CurrencyManager.get_currency_amount(GameEnums.CurrencyType.SPIRIT),
		
		# 2. UPGRADES
		"upgrades": UpgradeManager.upgrade_levels,
		
		# 3. STORY FLAGS
		"flags": GameStats.story_flags,
		
		# 4. VITALS
		"vitals": _get_vitals_data(),
		
		# 5. META
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data)
		file.store_string(json_str)
		print("Game Saved! Path: " + SAVE_PATH)
	else:
		printerr("Failed to open save file for writing.")

func load_game() -> void:
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
	
	# --- 1. RESTORE CURRENCY ---
	if "money" in data:
		CurrencyManager._wallet[GameEnums.CurrencyType.MONEY] = data["money"]
		CurrencyManager.currency_changed.emit(GameEnums.CurrencyType.MONEY, data["money"])
		
	if "spirit" in data:
		CurrencyManager._wallet[GameEnums.CurrencyType.SPIRIT] = data["spirit"]
		CurrencyManager.currency_changed.emit(GameEnums.CurrencyType.SPIRIT, data["spirit"])
		
	# --- 2. RESTORE UPGRADES ---
	if "upgrades" in data:
		UpgradeManager.upgrade_levels.clear()
		for id in data["upgrades"]:
			var level = int(data["upgrades"][id])
			var str_id = str(id)
			
			UpgradeManager.upgrade_levels[str_id] = level
			# Emit so UI updates immediately
			UpgradeManager.upgrade_leveled_up.emit(str_id, level)

	# --- 3. RESTORE STORY FLAGS ---
	if "flags" in data:
		GameStats.story_flags = data["flags"]

	# --- 4. RESTORE VITALS ---
	if "vitals" in data:
		_restore_vitals(data["vitals"])

	print("Game Loaded Successfully!")

func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# --- HELPER FUNCTIONS ---

func _get_vitals_data() -> Dictionary:
	var v_data = {}
	# Assuming VitalManager exposes its 'vitals' dictionary or keys
	var types = [
		GameEnums.VitalType.ENERGY, 
		GameEnums.VitalType.FULLNESS,
		GameEnums.VitalType.FOCUS,
		GameEnums.VitalType.SANITY
	]
	
	for t in types:
		# Ensure VitalManager is using the correct 'current' getter
		v_data[str(t)] = VitalManager.get_current(t)
	
	return v_data

func _restore_vitals(v_data: Dictionary) -> void:
	for key in v_data:
		var type = int(key)
		var amount = float(v_data[key]) # Fixed the syntax error here
		
		# Set current value directly
		if type in VitalManager.vitals:
			VitalManager.vitals[type]["current"] = amount
			# Emit signal to update UI bars
			VitalManager.vital_changed.emit(type, amount, VitalManager.get_max(type))
