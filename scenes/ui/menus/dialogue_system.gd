extends CanvasLayer

# Singleton access
static var instance: Node

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/HBoxContainer/Portrait
@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $PanelContainer/HBoxContainer/VBoxContainer/TextLabel
@onready var next_button: Button = $PanelContainer/HBoxContainer/NextButton
@onready var option_list: VBoxContainer = $PanelContainer/HBoxContainer/OptionList

var current_conversation: Conversation
var current_index: int = 0
var is_typing: bool = false

func _ready():
	instance = self
	visible = false # Hide on start
	next_button.pressed.connect(_on_next_pressed)

# --- PUBLIC API ---
func start_conversation(conv: Conversation):
	if not conv or conv.lines.is_empty(): return
	
	current_conversation = conv
	current_index = 0
	visible = true
	_show_line()

# --- INTERNAL LOGIC ---
func _show_line():
	var line = current_conversation.lines[current_index]
	
	# Set Content
	name_label.text = line.speaker_name
	text_label.text = line.text
	
	# Handle Portrait (Hide if null)
	if line.portrait:
		portrait_rect.texture = line.portrait
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false
	
	# Reset Typewriter Effect
	text_label.visible_ratio = 0.0
	is_typing = true
	
	# Tween the text appearance (Juice!)
	var tween = create_tween()
	var duration = line.text.length() * 0.03 # 0.03 sec per character
	tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	tween.tween_callback(func(): is_typing = false)
	
	for child in option_list.get_children():
		child.queue_free()
	
	# DECISION: Is this a Choice or just Text?
	if line.options.size() > 0:
		# Mode A: Choices
		next_button.visible = false # Hide the arrow
		_spawn_options(line.options)
	else:
		# Mode B: Normal Text
		next_button.visible = true

func _on_next_pressed():
	# 1. If still typing, skip to end immediately
	if is_typing:
		# Kill active tweens on the label (optional complexity) or just force it:
		text_label.visible_ratio = 1.0
		is_typing = false
		return
		
	# 2. Advance to next line
	current_index += 1
	
	if current_index < current_conversation.lines.size():
		_show_line()
	else:
		_end_conversation()

func _end_conversation():
	visible = false
	current_conversation = null
	# Optional: Resume game / Unpause

func _spawn_options(options: Array[DialogueOption]):
	for opt in options:
		var btn = Button.new()
		btn.text = opt.text
		# Connect the click, passing the option data along
		btn.pressed.connect(func(): _on_option_clicked(opt))
		option_list.add_child(btn)

func _on_option_clicked(opt: DialogueOption):
	# 1. Trigger external game actions (e.g. Open Shop)
	if opt.action_id != "":
		SignalBus.dialogue_action.emit(opt.action_id)
	
	# 2. Decide what happens to the dialogue box
	if opt.next_conversation:
		start_conversation(opt.next_conversation)
	elif opt.close_dialogue:
		_end_conversation()
