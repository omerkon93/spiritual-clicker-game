extends Button
class_name ActionButton

# --- DATA ---
@export var action_data: ActionData:
	set(value):
		action_data = value
		# If the node is already in the scene, update immediately!
		if is_node_ready(): 
			_load_data_into_components()

# --- COMPONENTS ---
@export_category("Components")
@export_group("Local Components")
@export var cost_component: CostComponent
@export var reward_component: RewardComponent
@export var message_component: MessageComponent
@export var streak_component: StreakComponent

# --- SETTINGS ---
@export_category("Settings")
@export var base_cooldown: float = 0.5 # Will be overwritten by ActionData

@export_group("Upgrades")
@export var primary_upgrade: LevelableUpgrade
@export var contributing_upgrades: Array[LevelableUpgrade] = []

# --- DEPENDENCIES ---
@onready var timer: Timer = $CooldownTimer
@export var progress_bar: TextureProgressBar

# --- VISUAL REFERENCES ---
@onready var title_label: Label = %TitleLabel
@onready var details_label: Label = %DetailsLabel
@onready var icon_rect: TextureRect = %IconRect

var current_cooldown: float = 1.0

func _ready() -> void:
	pressed.connect(_on_clicked)
	UpgradeManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	
	_validate_and_connect_components()
	
	if action_data:
		_load_data_into_components()
	
	# Initial calculation to set the correct Cooldown before the first click
	_recalculate_upgrades()

func _process(_delta: float) -> void:
	if timer and not timer.is_stopped() and progress_bar:
		progress_bar.visible = true
		progress_bar.value = (timer.time_left / timer.wait_time) * 100
	elif progress_bar:
		progress_bar.visible = false

func _on_clicked() -> void:
	if timer and not timer.is_stopped(): return

	# 1. CHECK AFFORDABILITY
	if not cost_component.check_affordability():
		play_shake()
		return

	# 2. EXECUTE ACTION
	cost_component.pay_all()
	
	# The reward component now knows about our extra power!
	var feedback: Array[Dictionary] = reward_component.deliver_rewards()
	_visualize_feedback(feedback)
	
	# 3. ANNOUNCE TO GAME
	SignalBus.action_triggered.emit(action_data)

	# 4. COOLDOWN
	if timer: timer.start(current_cooldown)
	_play_bounce_animation()

# --- HELPERS ---

func _validate_and_connect_components() -> void:
	if not cost_component: cost_component = get_node_or_null("CostComponent")
	if not reward_component: reward_component = get_node_or_null("RewardComponent")
	if not message_component: message_component = get_node_or_null("MessageComponent")
	if not streak_component: streak_component = get_node_or_null("StreakComponent")
	
	if cost_component and message_component:
		if not cost_component.check_failed.is_connected(message_component.on_check_failed):
			cost_component.check_failed.connect(message_component.on_check_failed)

	if streak_component and cost_component:
		streak_component.cost_component = cost_component

func _load_data_into_components() -> void:
	if not action_data: return

	# 1. SYNC SETTINGS
	# The Resource is the "Source of Truth"
	base_cooldown = action_data.base_duration
	
	# We set this temporarily; _recalculate_upgrades will finalize it momentarily
	current_cooldown = base_cooldown
	if timer: 
		timer.wait_time = current_cooldown
		timer.one_shot = true 

	# 2. SYNC VISUALS
	_update_ui()

	# 3. CONFIGURE COMPONENTS
	if cost_component: cost_component.configure(action_data)
	if reward_component: reward_component.configure(action_data)
	
	if message_component and not action_data.failure_messages.is_empty():
		message_component.failure_messages = action_data.failure_messages.duplicate()
		
	if streak_component: streak_component.configure(action_data)

func _update_ui() -> void:
	if not action_data: return
	
	# Set Title
	if title_label: 
		title_label.text = action_data.display_name
	
	# Set Icon
	if icon_rect and action_data.icon:
		icon_rect.texture = action_data.icon
		
	# Set Tooltip
	if action_data.description != "":
		tooltip_text = action_data.description
		
	# Set Details (Optional placeholder)
	if details_label:
		details_label.text = "Click to Start"

func _recalculate_upgrades() -> void:
	var total_extra_power: float = 0.0
	var reduction_time: float = 0.0
	
	var all_upgrades: Array[LevelableUpgrade] = contributing_upgrades.duplicate()
	if primary_upgrade:
		all_upgrades.append(primary_upgrade)
	
	for upg: LevelableUpgrade in all_upgrades:
		var lvl: int = UpgradeManager.get_upgrade_level(upg.id)
		
		if lvl > 0:
			var effect: float = upg.power_per_level * lvl
			match upg.target_stat:
				GameEnums.StatType.CLICK_POWER:
					total_extra_power += effect
				GameEnums.StatType.CLICK_COOLDOWN:
					reduction_time += effect
	
	# Apply Power
	if reward_component and reward_component.has_method("recalculate_finals"):
		reward_component.recalculate_finals(total_extra_power)
	
	# Apply Cooldown Reduction (Don't let it go below 0.1s)
	current_cooldown = max(0.1, base_cooldown - reduction_time)
	if timer: timer.wait_time = current_cooldown

func _on_upgrade_leveled(id: String, _lvl: int) -> void:
	var is_relevant: bool = false
	if primary_upgrade and primary_upgrade.id == id:
		is_relevant = true
	else:
		for upg in contributing_upgrades:
			if upg.id == id:
				is_relevant = true
				break
	
	if is_relevant:
		_recalculate_upgrades()

# --- VISUALS ---

func play_shake() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", position.x + 5, 0.05)
	tween.tween_property(self, "position:x", position.x - 5, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)

func _visualize_feedback(events: Array[Dictionary]) -> void:
	for event: Dictionary in events:
		_spawn_floating_text(event.get("text", ""), event.get("color", Color.WHITE))

func _spawn_floating_text(floating_text: String, color: Color) -> void:
	var pos: Vector2 = get_global_mouse_position()
	pos.x += randf_range(-20, 20)
	pos.y += randf_range(-20, 20)
	SignalBus.request_floating_text.emit(pos, floating_text, color)

func _play_bounce_animation() -> void:
	pivot_offset = size / 2
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.05)
