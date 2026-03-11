extends Button
class_name ItemInfoButton

var info_title: String = ""
var info_desc: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)

# Any UI can call this to set up the button
func setup(t: String, d: String) -> void:
	info_title = t
	info_desc = d
	visible = info_desc != ""

func _on_pressed() -> void:
	SignalBus.show_info_requested.emit(info_title, info_desc)
