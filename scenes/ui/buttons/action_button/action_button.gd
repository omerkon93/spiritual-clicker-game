extends Button
class_name ActionButton

# ==============================================================================
# 1. DATA & CONFIGURATION
# ==============================================================================

# --- DATA RESOURCE ---
@export var action_data: ActionData:
	set(value):
		action_data = value
		if is_node_ready(): 
			_load_data_into_components()

# --- COMPONENT REFERENCES ---
@export_category("Components")
@export_group("Local Components")
@export var cost_component: CostComponent
@export var reward_component: RewardComponent
@export var message_component: MessageComponent
@export var streak_component: StreakComponent
@export var animation_component: AnimationComponent

# --- SETTINGS ---
@export_category("Settings")
@export var base_cooldown: float = 0.5 

@export_group("Upgrades")
@export var primary_upgrade: GameItem
@export var contributing_upgrades: Array[GameItem] = []

# --- DEPENDENCIES ---
@onready var timer: Timer = $CooldownTimer

# --- VISUAL REFERENCES ---
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel 
@onready var icon_rect: TextureRect = %IconRect

# We use unique name (%) because it might be deeply nested, or standard ($) if direct child
@onready var notification_indicator_component: NotificationIndicatorComponent = %NotificationIndicatorComponent

var current_cooldown: float = 1.0

# ==============================================================================
# 2. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	pressed.connect(_on_clicked)
	
	# Connect to ProgressionManager for level updates
	ProgressionManager.upgrade_leveled_up.connect(_on_upgrade_leveled)
	
	_validate_and_connect_components()
	
	if action_data: 
		_load_data_into_components()
		_recalculate_upgrades() 
	
	if animation_component and icon_rect:
		animation_component.target_control = icon_rect


# ==============================================================================
# 3. INTERACTION
# ==============================================================================
func _on_clicked() -> void:
	if timer and not timer.is_stopped(): 
		return

	# --- NEW: DELEGATE "SEEN" LOGIC ---
	if notification_indicator_component:
		notification_indicator_component.mark_as_seen()

	# 1. CHECK AFFORDABILITY
	if cost_component and not cost_component.check_affordability():
		if animation_component: animation_component.play_shake()
		return

	# 2. EXECUTE
	if cost_component: cost_component.pay_all()
	
	if action_data:
		TimeManager.advance_time(action_data.time_cost_minutes)
	
	# 3. REWARDS & VISUALS
	var feedback = []
	if reward_component:
		feedback = reward_component.deliver_rewards()
	
	if animation_component: 
		animation_component.visualize_feedback(feedback)
		animation_component.play_bounce()

	# 4. GAME STATE UPDATE
	SignalBus.action_triggered.emit(action_data)

	if timer: timer.start(current_cooldown)


# ==============================================================================
# 4. SETUP HELPERS
# ==============================================================================
func _validate_and_connect_components() -> void:
	if not cost_component: cost_component = get_node_or_null("CostComponent")
	if not reward_component: reward_component = get_node_or_null("RewardComponent")
	if not message_component: message_component = get_node_or_null("MessageComponent")
	if not streak_component: streak_component = get_node_or_null("StreakComponent")
	if not animation_component: animation_component = get_node_or_null("AnimationComponent")

func _load_data_into_components() -> void:
	if not action_data: return
	
	base_cooldown = action_data.base_duration
	current_cooldown = base_cooldown
	if timer: timer.wait_time = current_cooldown

	_update_ui()

	# --- NEW: CONFIGURE NOTIFICATION ---
	if notification_indicator_component:
		# We pass 'self' as the target so the BUTTON blinks, not just the indicator
		notification_indicator_component.configure(action_data.id, self)

	if cost_component: cost_component.configure(action_data)
	if reward_component: reward_component.configure(action_data)
	if message_component: message_component.failure_messages = action_data.failure_messages.duplicate()

# ==============================================================================
# 5. UI UPDATES
# ==============================================================================
func _update_ui() -> void:
	if not action_data: return
	if title_label: title_label.text = action_data.display_name
	if icon_rect: icon_rect.texture = action_data.icon
	if action_data.description != "": tooltip_text = action_data.description
	_generate_stats_text()

func _generate_stats_text() -> void:
	if not action_data or not stats_label: return
	
	var text_lines: Array[String] = []
	
	# COSTS
	for type_key in action_data.currency_costs:
		var amount = action_data.currency_costs[type_key]
		if amount <= 0: continue
		var type = type_key as int 
		var def = CurrencyManager.get_definition(type)
		if def: text_lines.append("[color=salmon]-%s%s[/color]" % [def.prefix, amount])

	for type_key in action_data.vital_costs:
		var amount = action_data.vital_costs[type_key]
		if amount <= 0: continue
		var type = type_key as int 
		var def = VitalManager.get_definition(type)
		if def: text_lines.append("[color=salmon]-%s %s[/color]" % [amount, def.display_name])

	# REWARDS
	for type_key in action_data.currency_gains:
		var amount = action_data.currency_gains[type_key]
		if amount <= 0: continue
		var type = type_key as int
		var def = CurrencyManager.get_definition(type)
		if def: text_lines.append("[color=light_green]+%s%s[/color]" % [def.prefix, amount])

	for type_key in action_data.vital_gains:
		var amount = action_data.vital_gains[type_key]
		if amount <= 0: continue
		var type = type_key as int
		var def = VitalManager.get_definition(type)
		if def: text_lines.append("[color=cyan]+%s %s[/color]" % [amount, def.display_name])

	stats_label.text = "[center]%s[/center]" % "\n".join(text_lines)

# ==============================================================================
# 7. UPGRADE LOGIC
# ==============================================================================
func _recalculate_upgrades() -> void:
	var total_extra_power: float = 0.0
	var reduction_time: float = 0.0
	
	var all_upgrades: Array[GameItem] = contributing_upgrades.duplicate()
	if primary_upgrade:
		all_upgrades.append(primary_upgrade)
	
	for upg: GameItem in all_upgrades:
		if upg == null: continue
		var lvl: int = ProgressionManager.get_upgrade_level(upg.id)
		
		if lvl > 0:
			var effect: float = upg.power_per_level * lvl
			match int(upg.target_stat):
				StatDefinition.StatType.CLICK_POWER: total_extra_power += effect
				StatDefinition.StatType.CLICK_COOLDOWN: reduction_time += effect
	
	if reward_component and reward_component.has_method("recalculate_finals"):
		reward_component.recalculate_finals(total_extra_power)
	
	current_cooldown = max(0.1, base_cooldown - reduction_time)
	if timer: timer.wait_time = current_cooldown

func _on_upgrade_leveled(id: String, _lvl: int) -> void:
	var is_relevant: bool = false
	if primary_upgrade and primary_upgrade.id == id: is_relevant = true
	else:
		for upg in contributing_upgrades:
			if upg and upg.id == id:
				is_relevant = true
				break
	if is_relevant: _recalculate_upgrades()
