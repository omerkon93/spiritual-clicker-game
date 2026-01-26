class_name ClickProducer extends Node

# --- Configuration ---
@export var currency_type: GameEnums.CurrencyType = GameEnums.CurrencyType.MONEY # Default to Work
@export var base_cooldown: float = 2.0 # Time in seconds between clicks (default slow)

# --- Dependencies ---
# We assume these nodes exist as children of the ClickProducer
@onready var timer: Timer = $CooldownTimer
@export var progress_bar: TextureProgressBar

# --- Upgrades ---
@export var contributing_upgrades: Array[LevelableUpgrade] = []

# --- Visual Settings ---
@export_group("Visuals")
@export var bounce_scale: Vector2 = Vector2(0.9, 0.9)
@export var bounce_duration: float = 0.05

# --- Local Cache (Calculated Stats) ---
@export_group("Stats")
@export var current_power: float
var current_cooldown: float = 2.0

func _ready():
	# 1. Parent Connection Logic
	var parent = get_parent()
	if parent is BaseButton:
		parent.pressed.connect(_on_clicked)
	elif parent is Control:
		parent.gui_input.connect(_on_gui_input)
	
	# 2. Upgrade Listener
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	
	# 3. Setup UI
	if progress_bar:
		progress_bar.max_value = 100
		progress_bar.value = 0
		progress_bar.visible = false
	
	# 4. Initial Stat Calculation
	_recalculate_stats()
	_update_visuals()

func _process(_delta):
	# Update the Cooldown Bar every frame
	if timer and not timer.is_stopped():
		var time_left = timer.time_left
		var total_time = timer.wait_time
		
		# Calculate percentage (100% = Just clicked, 0% = Ready)
		# We flip it so the bar fills up or empties based on your preference
		var pct = (time_left / total_time) * 100
		
		if progress_bar:
			progress_bar.value = pct
			progress_bar.visible = true
	else:
		if progress_bar: progress_bar.visible = false

func _on_clicked():
	# --- 1. THE GATEKEEPER ---
	# If the timer is running, the click is ignored (Cooldown is active)
	if timer and not timer.is_stopped():
		return 

	# --- 2. ADD CURRENCY ---
	# We use the locally calculated 'current_power'
	Bank.add_currency(currency_type, current_power)
	
	# --- 3. START COOLDOWN ---
	if timer:
		timer.start(current_cooldown)
	
	# --- 4. VISUALS & JUICE ---
	var mouse_pos = get_viewport().get_mouse_position()
	var text_str = "+" + NumberFormatter.format_value(current_power)
	
	# Note: I changed Color.GOLD to Color.WHITE for generic 'Work', change back if you want
	SignalBus.request_floating_text.emit(mouse_pos, text_str, Color.WHITE)
	# Removed message_logged to avoid spamming chat every click
	
	_play_bounce_animation()
	_play_click_sound()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _recalculate_stats():
	var added_power = 0.0
	var removed_time = 0.0
	
	for upgrade in contributing_upgrades:
		var level = UpgradeManager.get_upgrade_level(upgrade.id)
		if level > 0:
			var total_effect = upgrade.power_per_level * level 
			
			match upgrade.effect_type:
				LevelableUpgrade.EffectType.CLICK_POWER:
					added_power += total_effect
				LevelableUpgrade.EffectType.COOLDOWN_REDUCTION:
					removed_time += total_effect
	
	# FIX 1: Use snapped() to fix 5.99999 becoming 5
	# snapped(value, 0.1) rounds to the nearest 0.1
	if added_power > 0:
			current_power = added_power
	else:
		current_power = 1.0
	
	# FIX 2: Clamp cooldown safely
	current_cooldown = max(0.1, base_cooldown - removed_time)
	
	# DEBUG: Uncomment this to see the "Real" math in the console
	print("Power: %s | Cooldown: %s" % [current_power, current_cooldown])

func _play_bounce_animation():
	var parent = get_parent()
	if not (parent is Control or parent is Node2D): return
	
	if parent is Control:
		parent.pivot_offset = parent.size / 2
	
	var tween = create_tween()
	tween.tween_property(parent, "scale", bounce_scale, bounce_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(parent, "scale", Vector2.ONE, bounce_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _play_click_sound():
	var sound_to_play: AudioStream = null
	
	for i in range(contributing_upgrades.size() - 1, -1, -1):
		var upg = contributing_upgrades[i]
		# Check if we own it AND it has sound
		if UpgradeManager.get_upgrade_level(upg.id) > 0 and upg.audio_on_use:
			sound_to_play = upg.audio_on_use
			break
			
	if sound_to_play:
		SoundManager.play_sfx(sound_to_play, 1.0, 0.1)

func _update_visuals():
	var sprite_to_use: Texture2D = null
	
	for upg in contributing_upgrades:
		if UpgradeManager.get_upgrade_level(upg.id) > 0:
			if upg.world_sprite:
				sprite_to_use = upg.world_sprite
	
	if sprite_to_use:
		var parent = get_parent()
		if parent is TextureButton:
			parent.texture_normal = sprite_to_use
		elif parent is Button:
			parent.icon = sprite_to_use
		elif parent is TextureRect:
			parent.texture = sprite_to_use

# When an upgrade happens, we recalculate stats AND visuals
func _on_upgrade_leveled(_id: String, _lvl: int):
	_recalculate_stats()
	_update_visuals()
