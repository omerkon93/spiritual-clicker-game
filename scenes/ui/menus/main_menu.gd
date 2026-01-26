extends Control

# Path to your actual game scene
const GAME_SCENE_PATH = "res://scenes/test/test_world.tscn"

@onready var button_start: Button = $CenterContainer/VBoxContainer/ButtonStart
@onready var button_load: Button = $CenterContainer/VBoxContainer/ButtonLoad
@onready var button_settings: Button = $CenterContainer/VBoxContainer/ButtonSettings
@onready var button_exit: Button = $CenterContainer/VBoxContainer/ButtonExit

func _ready():
	# Connect buttons
	button_start.pressed.connect(_on_start_pressed)
	button_load.pressed.connect(_on_load_pressed)
	button_exit.pressed.connect(_on_exit_pressed)
	
	# Check if a save file exists. If not, disable "Continue".
	if not SaveSystem.save_file_exists(): # You might need to add this helper to SaveSystem
		button_load.disabled = true
		button_load.text = "No Save Found"

func _on_start_pressed():
	# For a "New Game", we might want to wipe the old save or just start fresh
	# For safety, let's just load the scene. The game logic handles the rest.
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_load_pressed():
	# We load the scene. The SaveSystem usually loads automatically in _ready 
	# OR we can pass a flag to tell it "Load immediately".
	SaveSystem.load_game()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_exit_pressed():
	get_tree().quit()
