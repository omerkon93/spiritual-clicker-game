extends Button

func _ready():
	pressed.connect(func(): get_tree().quit())
