extends Control

const GAME_SCENE_PATH = "uid://dnql0wnfnqy0d"

# Assuming you added the SettingsMenu as a child of MainMenu in the editor
@onready var settings_menu: Control = $SettingsMenu 

@onready var button_start: Button = $CenterContainer/VBoxContainer/ButtonStart
@onready var button_load: Button = $CenterContainer/VBoxContainer/ButtonLoad
@onready var button_settings: Button = $CenterContainer/VBoxContainer/ButtonSettings #
@onready var button_exit: Button = $CenterContainer/VBoxContainer/ButtonExit

func _ready():
	button_start.pressed.connect(_on_start_pressed)
	button_load.pressed.connect(_on_load_pressed)
	button_settings.pressed.connect(_on_settings_pressed) # Connect this!
	button_exit.pressed.connect(_on_exit_pressed)
	
	# Check for save file
	if not SaveSystem.save_file_exists(): #
		button_load.disabled = true
		button_load.text = "No Save Found"

func _on_start_pressed():
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_pressed():
	# Flag the system to load automatically when the world is ready
	SaveSystem.load_game() #
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_settings_pressed():
	if settings_menu:
		settings_menu.open()

func _on_exit_pressed():
	get_tree().quit()
