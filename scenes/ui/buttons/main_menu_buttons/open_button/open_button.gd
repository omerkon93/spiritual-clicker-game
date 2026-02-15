extends Button

# Export allows you to drag and drop the SettingsMenu node here in the Inspector
@export var chosen_menu: Control

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	if chosen_menu:
		# Acts as a toggle switch
		chosen_menu.visible = not chosen_menu.visible
		
		# Optional: If your settings menu has specific open/close logic
		# you can use this instead:
		# if settings_menu.visible:
		# 	settings_menu.close() 
		# else:
		# 	settings_menu.open()
