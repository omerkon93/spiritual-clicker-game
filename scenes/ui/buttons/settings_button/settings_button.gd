extends Button

@export var settings_menu: Control

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	settings_menu.open()
