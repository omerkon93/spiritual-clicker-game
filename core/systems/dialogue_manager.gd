extends CanvasLayer

# Singleton access
static var instance: Node

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/HBoxContainer/Portrait
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $PanelContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var next_button: Button = $PanelContainer/HBoxContainer/NextButton
@onready var option_list: VBoxContainer = $PanelContainer/HBoxContainer/OptionList

var current_sequence: DialogueSequence
var current_index: int = 0
var is_typing: bool = false

func _ready() -> void:
	instance = self
	visible = false 
	next_button.pressed.connect(_on_next_pressed)

# --- PUBLIC API ---
func start_dialogue(conv: DialogueSequence) -> void:
	if not conv or conv.slides.is_empty(): return
	
	current_sequence = conv
	current_index = 0
	visible = true
	_show_slide()

# --- INTERNAL LOGIC ---
func _show_slide() -> void:
	# NOTE: Changed from 'lines' to 'slides' to match your new resource
	var slide: DialogueSlide = current_sequence.slides[current_index]
	
	# 1. Set Content
	name_label.text = slide.speaker_name
	text_label.text = slide.text
	
	if slide.portrait:
		portrait_rect.texture = slide.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	# 2. Typewriter Effect
	text_label.visible_ratio = 0.0
	is_typing = true
	
	var tween = create_tween()
	var duration = slide.text.length() * 0.03
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.tween_callback(func(): is_typing = false)
	
	# 3. Clear old buttons
	for child in option_list.get_children():
		child.queue_free()
	
	# 4. Spawn Options (Dictionary Logic)
	if not slide.options.is_empty():
		next_button.visible = false
		_spawn_options(slide.options)
	else:
		next_button.visible = true

func _spawn_options(options: Dictionary) -> void:
	# Loop through KEYS (The Button Text)
	for button_text: String in options:
		var target_resource = options[button_text]
		var btn = Button.new()
		btn.text = button_text
		btn.pressed.connect(func(): _on_option_clicked(target_resource))
		option_list.add_child(btn)

func _on_option_clicked(target: Resource) -> void:
	# 1. Is it a full Sequence? (The Book)
	if target is DialogueSequence:
		start_dialogue(target)
		
	# 2. NEW: Is it a single Slide? (The Page)
	elif target is DialogueSlide:
		var temp_sequence = DialogueSequence.new()
		var new_slides: Array[DialogueSlide] = []
		new_slides.append(target)
		temp_sequence.slides = new_slides
		start_dialogue(temp_sequence)

	# 3. Is it a Trigger? (The Signal)
	elif target is DialogueTrigger:
		if target.signal_id != "":
			SignalBus.dialogue_action.emit(target.signal_id)
		_end_dialogue()
		
	# 4. Is it Action Data? (The Transaction)
	elif target is ActionData:
		SignalBus.action_triggered.emit(target)
		if "trigger_signal_id" in target and target.trigger_signal_id != "":
			SignalBus.dialogue_action.emit(target.trigger_signal_id)
		_end_dialogue()

	else:
		_end_dialogue()

func _on_next_pressed() -> void:
	if is_typing:
		text_label.visible_ratio = 1.0
		is_typing = false
		return
		
	current_index += 1
	
	if current_index < current_sequence.slides.size():
		_show_slide()
	else:
		_end_dialogue()

func _end_dialogue() -> void:
	visible = false
	current_sequence = null
