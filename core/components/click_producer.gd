class_name ClickProducer extends Node

@export var currency_type: GameEnums.CurrencyType = GameEnums.CurrencyType.GOLD
@export var stat_def: StatDefinition
# Using the Array allows multiple upgrades to boost this click
@export var contributing_upgrades: Array[LevelableUpgrade] = []

# These variables to tweak the visuals
@export_group("Visuals")
@export var bounce_scale: Vector2 = Vector2(0.9, 0.9) # Shrink to 90%
@export var bounce_duration: float = 0.05

func _ready():
	var parent = get_parent()
	if parent is BaseButton:
		parent.pressed.connect(_on_clicked)
	elif parent is Control:
		parent.gui_input.connect(_on_gui_input)
	
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	
	_update_visuals()

func _on_clicked():
	if not stat_def: return

	# FIX: Trust GameStats to do the math. 
	# We removed the manual 'for' loop because get_stat_value now does that internally!
	var amount = GameStats.get_stat_value(stat_def, contributing_upgrades)
	
	Bank.add_currency(currency_type, amount)
	
	# Visuals
	var mouse_pos = get_viewport().get_mouse_position()
	var text_str = "+" + NumberFormatter.format_value(amount)
	
	SignalBus.request_floating_text.emit(mouse_pos, text_str, Color.GOLD)
	SignalBus.message_logged.emit("You gained 1 gold!", Color.GREEN)

	_play_bounce_animation()
	_play_click_sound()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _play_bounce_animation():
	var parent = get_parent()
	# Tweens work best on Control nodes (Buttons) or Node2Ds (Sprites)
	if not (parent is Control or parent is Node2D): return
	
	# CRITICAL: We must set the pivot to the center, otherwise it shrinks to the top-left corner!
	# We try to calculate center based on the node type
	if parent is Control:
		parent.pivot_offset = parent.size / 2
	
	# Create the Tween
	var tween = create_tween()
	
	# 1. Squash (Shrink fast)
	tween.tween_property(parent, "scale", bounce_scale, bounce_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# 2. Stretch (Return to normal)
	tween.tween_property(parent, "scale", Vector2.ONE, bounce_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _play_click_sound():
	# 1. Try to find a sound from the contributing upgrades
	var sound_to_play: AudioStream = null
	
	# Loop backwards to find the "highest tier" tool's sound
	for i in range(contributing_upgrades.size() - 1, -1, -1):
		var upg = contributing_upgrades[i]
		if upg.audio_on_use:
			sound_to_play = upg.audio_on_use
			break
			
	if sound_to_play:
		# Play with slight pitch variation (0.1) for variety!
		SoundManager.play_sfx(sound_to_play, 1.0, 0.1)

# Rename your old logic to this helper function so we can reuse it
func _update_visuals():
	var sprite_to_use: Texture2D = null
	
	# Loop through upgrades to find the best active one
	for upg in contributing_upgrades:
		if UpgradeManager.get_upgrade_level(upg.id) > 0:
			if upg.world_sprite:
				sprite_to_use = upg.world_sprite
	
	# Apply Visuals
	if sprite_to_use:
		var parent = get_parent()
		if parent is TextureButton:
			parent.texture_normal = sprite_to_use
		elif parent is Button:
			parent.icon = sprite_to_use
		elif parent is TextureRect:
			parent.texture = sprite_to_use

# Update your listener to use the helper
func _on_upgrade_leveled(_id: String, _lvl: int):
	_update_visuals()
