extends AcceptDialog
class_name ItemInfoPopup

func _ready() -> void:
	SignalBus.show_info_requested.connect(_on_show_info_requested)

func _on_show_info_requested(info_title: String, info_desc: String) -> void:
	title = "About " + info_title
	dialog_text = info_desc
	popup_centered()
