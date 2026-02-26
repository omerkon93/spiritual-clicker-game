extends Button
class_name CurrencyButton

# --- Configuration ---
@export var currency_type: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY
@export var base_cooldown: float = 2.0
@export var sanity_cost: float = 5.0 # Costs 5 sanity to work

# --- Dependencies ---
@onready var timer: Timer = $CooldownTimer
@export var progress_bar: TextureProgressBar # Drag CooldownBar here in Inspector

# --- Upgrades ---
@export var contributing_upgrades: Array[GameItem] = []

# --- Visual Settings ---
@export_group("Visuals")
@export var bounce_scale: Vector2 = Vector2(0.9, 0.9)
@export var bounce_duration: float = 0.05

# --- Local Cache ---
var current_power: float = 1.0
var current_cooldown: float = 2.0

func _ready():
	# 1. Self Connection
	pressed.connect(_on_clicked)
	
	# 2. Upgrade Listener
	ItemManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	
	# 3. Setup UI
	if progress_bar:
		progress_bar.max_value = 100
		progress_bar.value = 0
		progress_bar.visible = false
	
	# 4. Initial Calc
	_recalculate_stats()
	_update_visuals()

func _process(_delta):
	if timer and not timer.is_stopped():
		var pct = (timer.time_left / timer.wait_time) * 100
		if progress_bar:
			progress_bar.value = pct
			progress_bar.visible = true
	else:
		if progress_bar: progress_bar.visible = false

func _on_clicked():
	# 1. Cooldown Check
	if timer and not timer.is_stopped():
		return 

	# 2. Vital Check (NEW)
	# We ask the VitalManager if we have enough Sanity
	if not VitalManager.consume(VitalDefinition.VitalType.SANITY, sanity_cost):
		SignalBus.message_logged.emit("I'm too burnt out...", Color.RED)
		_play_bounce_animation() # Visual feedback for failure
		return
		
	# 3. Payday (Existing)
	CurrencyManager.add_currency(currency_type, current_power)
	
	if timer:
		timer.start(current_cooldown)
	
	# 3. Visuals
	var mouse_pos = get_viewport().get_mouse_position()
	var text_str = "+" + NumberFormatter.format_value(current_power)
	SignalBus.request_floating_text.emit(mouse_pos, text_str, Color.GREEN) # Changed to Green for Money
	
	_play_bounce_animation()
	_play_click_sound()

func _recalculate_stats():
	var added_power = 0.0
	var removed_time = 0.0
	
	for upgrade in contributing_upgrades:
		var level = ItemManager.get_upgrade_level(upgrade.id)
		if level > 0:
			var total_effect = upgrade.power_per_level * level 
			
			# NEW LOGIC: Check the Global StatType
			match upgrade.target_stat:
				StatDefinition.StatType.ACTION_POWER:
					added_power += total_effect
				
				StatDefinition.StatType.ACTION_TIME_EFFICIENCY:
					removed_time += total_effect
	
	# Logic: If we have upgrades, use them. Otherwise default to 1.
	if added_power > 0:
		current_power = added_power
	else:
		current_power = 1.0
		
	current_cooldown = max(0.1, base_cooldown - removed_time)

func _play_bounce_animation():
	# Pivot needs to be center for correct scaling
	self.pivot_offset = self.size / 2
	
	var tween = create_tween()
	tween.tween_property(self, "scale", bounce_scale, bounce_duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, bounce_duration)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _play_click_sound():
	var sound_to_play: AudioStream = null
	for i in range(contributing_upgrades.size() - 1, -1, -1):
		var upg = contributing_upgrades[i]
		if ItemManager.get_upgrade_level(upg.id) > 0 and upg.audio_on_use:
			sound_to_play = upg.audio_on_use
			break
	if sound_to_play:
		SoundManager.play_sfx(sound_to_play, 1.0, 0.1)

func _update_visuals():
	var sprite_to_use: Texture2D = null
	for upg in contributing_upgrades:
		if ItemManager.get_upgrade_level(upg.id) > 0 and upg.world_sprite:
			sprite_to_use = upg.world_sprite
	
	if sprite_to_use:
		self.texture_normal = sprite_to_use

func _on_upgrade_leveled(_id: String, _lvl: int):
	_recalculate_stats()
	_update_visuals()
