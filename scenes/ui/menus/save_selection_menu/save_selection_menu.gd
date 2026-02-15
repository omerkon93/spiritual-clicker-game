extends Control

signal back_requested

# --- CONFIGURATION ---
# UPDATE THIS PATH to match your actual game scene!
const GAME_SCENE_PATH = "uid://dnql0wnfnqy0d" 
# Or use a file path like: "res://scenes/game/world.tscn"

# --- UI REFERENCES ---
@onready var title_label: Label = $VBoxContainer/TitleLabel 
@onready var back_btn: Button = %BackButton
@onready var slot_buttons = [ %SlotButton1, %SlotButton2, %SlotButton3 ]

# --- STATE ---
var is_save_mode: bool = false

func _ready():
	back_btn.pressed.connect(func(): 
		hide()
		back_requested.emit()
	)
	
	for btn in slot_buttons:
		# Pass the button itself so we can read its slot_id
		btn.pressed.connect(_on_slot_pressed.bind(btn))
	
	hide()

# --- PUBLIC METHODS ---
func open(save_mode: bool):
	show()
	is_save_mode = save_mode
	_update_ui_mode()

# --- INTERNAL LOGIC ---
func _update_ui_mode():
	if title_label:
		if is_save_mode:
			title_label.text = "SELECT SLOT TO SAVE"
			title_label.modulate = Color(1, 0.5, 0.5)
		else:
			title_label.text = "SELECT SLOT TO LOAD"
			title_label.modulate = Color(1, 1, 1)

	for btn in slot_buttons:
		btn.refresh_state(1 if is_save_mode else 0)

func _on_slot_pressed(btn: Button):
	var slot_id = btn.slot_id 
	
	if is_save_mode:
		# --- SAVE LOGIC ---
		SaveManager.current_slot_id = slot_id
		SaveManager.save_game()
		
		# Refresh UI to show the new timestamp
		_update_ui_mode() 
		
	else:
		# --- LOAD / NEW GAME LOGIC ---
		if SaveManager.save_file_exists(slot_id):
			SaveManager.load_game(slot_id)
		else:
			SaveManager.start_new_game(slot_id)
		
		# --- MISSING PIECE WAS HERE! ---
		# We need to actually switch to the game scene now
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
