extends Button

@export var save_selection_menu: Control

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if save_selection_menu:
		save_selection_menu.open(false)
