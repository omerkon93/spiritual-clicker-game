extends Control

@onready var label: RichTextLabel = $PanelContainer/RichTextLabel

func _ready():
	# Clear default text
	label.text = ""
	
	# Listen to the global signal (We will add this to SignalBus next)
	SignalBus.message_logged.connect(_add_message)
	
	# Welcome message
	_add_message("System: Game Loaded.", Color.GRAY)

func _add_message(text: String, color: Color = Color.WHITE):
	# BBCode magic for colors: [color=red]Text[/color]
	var hex = color.to_html()
	var formatted = "[color=#%s]%s[/color]" % [hex, text]
	
	# Append new line
	if label.text != "":
		label.text += "\n"
	
	label.text += formatted
