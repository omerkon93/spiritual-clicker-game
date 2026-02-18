extends Node

# Signal to tell the UI to update immediately when a setting changes
signal setting_changed(key: String, value: Variant)

# Default Settings
var _settings: Dictionary = {
	"time_format_24h": true,  # true = 24h (14:00), false = 12h (2:00 PM)
	"master_volume": 1.0,
	"music_volume": 1.0,
	"sfx_volume": 1.0
}

# --- GETTERS / SETTERS ---
func get_setting(key: String, default_val: Variant = null) -> Variant:
	return _settings.get(key, default_val)

func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	setting_changed.emit(key, value)
	# Optional: Trigger an auto-save of settings here if you want independent saving

# --- SAVE / LOAD (Connects to SaveManager) ---
func get_save_data() -> Dictionary:
	return _settings.duplicate()

func load_save_data(data: Dictionary) -> void:
	# Update internal dictionary
	for key in data:
		_settings[key] = data[key]
		# Emit signal so UI sliders/toggles update to match the loaded file
		setting_changed.emit(key, data[key])
