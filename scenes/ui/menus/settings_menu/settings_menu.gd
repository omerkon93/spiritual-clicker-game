extends Control

signal close_requested

# Indices for the AudioServer
var _bus_master: int
var _bus_music: int
var _bus_sfx: int

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

# NEW: Value Labels
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue

@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var reset_btn: Button = %ResetButton
@onready var back_btn: Button = %BackButton
@onready var save_btn: Button = %SaveButton
@onready var load_btn: Button = %LoadButton

func _ready() -> void:
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_music = AudioServer.get_bus_index("Music")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	
	# Connect signals (Pass both Bus Index AND the Label to update)
	master_slider.value_changed.connect(_on_volume_changed.bind(_bus_master, master_value))
	music_slider.value_changed.connect(_on_volume_changed.bind(_bus_music, music_value))
	sfx_slider.value_changed.connect(_on_volume_changed.bind(_bus_sfx, sfx_value))
	
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	reset_btn.pressed.connect(_on_reset_pressed)
	back_btn.pressed.connect(close)
	
	save_btn.pressed.connect(func(): SaveSystem.save_game())
	load_btn.pressed.connect(func(): SaveSystem.load_game())
	
	_load_current_settings()
	hide()

func open() -> void:
	show()
	_load_current_settings()

func close() -> void:
	hide()
	close_requested.emit()

func _load_current_settings() -> void:
	# Load values and manually trigger the text update
	var vol_master = db_to_linear(AudioServer.get_bus_volume_db(_bus_master))
	master_slider.value = vol_master
	_update_label(master_value, vol_master)

	var vol_music = db_to_linear(AudioServer.get_bus_volume_db(_bus_music))
	music_slider.value = vol_music
	_update_label(music_value, vol_music)

	var vol_sfx = db_to_linear(AudioServer.get_bus_volume_db(_bus_sfx))
	sfx_slider.value = vol_sfx
	_update_label(sfx_value, vol_sfx)
	
	fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

# Updated function to handle both Audio and Text
func _on_volume_changed(value: float, bus_idx: int, label: Label) -> void:
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(bus_idx, value < 0.05)
	
	# Update the text label
	_update_label(label, value)

func _update_label(label: Label, value: float) -> void:
	# Display as percentage (e.g., "85%")
	label.text = str(int(value * 100)) + "%"

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_reset_pressed() -> void:
	# Wipe the save file
	var dir = DirAccess.open("user://")
	if dir.file_exists("savegame.json"):
		dir.remove("savegame.json")
		print("Save file deleted.")
		
		reset_btn.text = "Data Wiped!"
		reset_btn.disabled = true
