extends Control

# --- SIGNALS ---
signal close_requested

# --- AUDIO BUS INDICES ---
var _bus_master: int
var _bus_music: int
var _bus_sfx: int

# --- UI NODES: SLIDERS ---
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

# --- UI NODES: LABELS ---
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue

# --- UI NODES: TOGGLES & BUTTONS ---
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var time_format_check: CheckBox = %TimeFormatCheck
@onready var reset_btn: Button = %ResetButton
@onready var back_btn: Button = %BackButton
@onready var save_btn: Button = %SaveButton
@onready var load_btn: Button = %LoadButton


# ==============================================================================
# 1. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# 1. Fetch Audio Bus Indices (so we don't look them up every frame)
	_bus_master = AudioServer.get_bus_index("Master")
	_bus_music = AudioServer.get_bus_index("Music")
	_bus_sfx = AudioServer.get_bus_index("SFX")
	
	# 2. Connect Audio Signals
	# Note: We use .bind() to pass extra data (Bus ID and Label) to the function
	master_slider.value_changed.connect(_on_volume_changed.bind(_bus_master, master_value))
	music_slider.value_changed.connect(_on_volume_changed.bind(_bus_music, music_value))
	sfx_slider.value_changed.connect(_on_volume_changed.bind(_bus_sfx, sfx_value))
	
	# 3. Connect Display/Game Settings
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	time_format_check.toggled.connect(_on_time_format_toggled)
	
	# 4. Connect Data Management Buttons
	reset_btn.pressed.connect(_on_reset_pressed)
	back_btn.pressed.connect(close)
	save_btn.pressed.connect(func(): SaveManager.save_game())
	load_btn.pressed.connect(func(): SaveManager.load_game())
	
	# 5. Initialize State
	_load_current_settings()
	hide() # Ensure menu is hidden on start


# ==============================================================================
# 2. PUBLIC METHODS
# ==============================================================================
func open() -> void:
	show()
	_load_current_settings() # Refresh UI in case settings changed elsewhere

func close() -> void:
	hide()
	close_requested.emit()


# ==============================================================================
# 3. PRIVATE HELPER METHODS
# ==============================================================================
func _load_current_settings() -> void:
	# --- Audio ---
	# Convert DB (Logarithmic) to Linear (0.0 - 1.0) for the slider
	var vol_master = db_to_linear(AudioServer.get_bus_volume_db(_bus_master))
	var vol_music = db_to_linear(AudioServer.get_bus_volume_db(_bus_music))
	var vol_sfx = db_to_linear(AudioServer.get_bus_volume_db(_bus_sfx))
	
	# Update Sliders
	master_slider.value = vol_master
	music_slider.value = vol_music
	sfx_slider.value = vol_sfx
	
	# Update Text Labels
	_update_label(master_value, vol_master)
	_update_label(music_value, vol_music)
	_update_label(sfx_value, vol_sfx)
	
	# --- Toggles ---
	# Check Window Mode
	var mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Check Time Format (From SettingsManager)
	time_format_check.button_pressed = SettingsManager.get_setting("time_format_24h", true)

func _update_label(label: Label, value: float) -> void:
	# Updates the % text next to the slider
	label.text = str(int(value * 100)) + "%"


# ==============================================================================
# 4. SIGNAL CALLBACKS
# ==============================================================================
func _on_volume_changed(value: float, bus_idx: int, label: Label) -> void:
	# Convert Linear slider value back to DB for AudioServer
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	
	# Mute if value is very low to prevent low-volume hissing
	AudioServer.set_bus_mute(bus_idx, value < 0.05)
	
	# Update the % label
	_update_label(label, value)

func _on_fullscreen_toggled(is_fullscreen: bool) -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_time_format_toggled(toggled_on: bool) -> void:
	# Update the SettingsManager directly
	SettingsManager.set_setting("time_format_24h", toggled_on)

func _on_reset_pressed() -> void:
	# Use the Manager to delete the save for safety
	SaveManager.delete_save()
	
	# Feedback to user
	reset_btn.text = "Data Wiped!"
	reset_btn.disabled = true
	
	# Optional: Reload the scene after a delay to reset state?
	# get_tree().reload_current_scene()
