extends PanelContainer
class_name TimeDisplay

# --- NODES ---
# We use the same structure as ResourceDisplay so you can reuse the prefab
@onready var icon_rect: TextureRect = $HBoxContainer/Icon
@onready var value_label: Label = $HBoxContainer/VBoxContainer/ValueLabel
@onready var progress_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar

# Optional: Export an icon for the clock
@export var clock_icon: Texture2D

func _ready() -> void:
	# 1. Setup Visuals
	if clock_icon:
		icon_rect.texture = clock_icon
	
	if progress_bar:
		progress_bar.visible = false
		
	# 2. Connect to TimeManager (Updates every game minute)
	TimeManager.time_updated.connect(_on_time_updated)
	
	# 3. Connect to SettingsManager (Updates instantly when you toggle the checkbox)
	SettingsManager.setting_changed.connect(_on_setting_changed)
	
	# 4. Initial Display
	_update_display()

func _on_time_updated(_day: int, _hour: int, _minute: int) -> void:
	_update_display()

# New: Handle setting changes
func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "time_format_24h":
		_update_display()

func _update_display() -> void:
	# Get Raw Data
	var day = TimeManager.current_day
	var hour = TimeManager.current_hour
	var minute = TimeManager.current_minute
	
	# Get Preference
	var is_24h = SettingsManager.get_setting("time_format_24h", true)
	
	var time_str = ""
	
	if is_24h:
		# Format: 14:30
		time_str = "%02d:%02d" % [hour, minute]
	else:
		# Format: 2:30 PM
		var suffix = "AM"
		var display_hour = hour
		
		if hour >= 12:
			suffix = "PM"
			if hour > 12:
				display_hour -= 12
		elif hour == 0:
			display_hour = 12 # Midnight
			
		time_str = "%d:%02d %s" % [display_hour, minute, suffix]
	
	# Update Label
	var day_str = "Day %d" % day
	value_label.text = "%s\n%s" % [day_str, time_str]
