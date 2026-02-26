extends MarginContainer
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
@export var notification_indicator_component: NotificationIndicatorComponent

# --- SETTINGS ---
@export_category("Settings")
@export var base_cooldown: float = 0.5 

@export_group("Upgrades")
@export var primary_upgrade: GameItem
@export var contributing_upgrades: Array[GameItem] = []

# --- DEPENDENCIES ---
@onready var timer: Timer = $CooldownTimer

# --- NEW TREE REFERENCES ---
# Get the invisible/background button to handle clicks
@onready var interact_button: Button = $Button 

# We use unique name (%) because it might be deeply nested, or standard ($) if direct child
@onready var title_label: Label = %TitleLabel
@onready var stats_label: RichTextLabel = %StatsLabel 
@onready var icon_rect: TextureRect = %IconRect


var current_cooldown: float = 1.0

# ==============================================================================
# 2. LIFECYCLE
# ==============================================================================
func _ready() -> void:
	# Connect to the actual button's signal
	if interact_button:
		interact_button.pressed.connect(_on_pressed)
	
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
func _on_pressed() -> void:
	if timer and not timer.is_stopped(): return

	# 1. CLEAR THE BADGE FIRST!
	if notification_indicator_component:
		notification_indicator_component.mark_as_seen()

	# 2. CHECK AFFORDABILITY 
	if cost_component and not cost_component.check_affordability():
		if animation_component: animation_component.play_shake()
		return

	# 3. INTERCEPT FOR DYNAMIC RANDOM TICKET
	var random_ticket = DialogueManager.get_random_ticket_for(action_data)
	
	if random_ticket != null:
		# Pay the entry cost (e.g., it costs 5 Focus to read a ticket)
		if cost_component: cost_component.pay_all()
		if timer: timer.start(current_cooldown)
		
		# Launch the UI
		DialogueManager.start_dialogue(random_ticket)
		return # ABORT! The dialogue choices handle the rewards.

	# 4. STANDARD EXECUTION (If the pool is empty, just act like a normal button)
	if cost_component: cost_component.pay_all()
	
	if action_data:
		TimeManager.advance_time(int(action_data.effective_time_cost))
	
	var feedback = []
	if reward_component:
		feedback = reward_component.deliver_rewards()
	
	if animation_component: 
		animation_component.visualize_feedback(feedback)
		animation_component.play_bounce()

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
	
	# 1. Update the Resource math
	action_data.recalculate_stats()
	
	# 2. Update the Components
	if reward_component:
		reward_component.configure(action_data)
		reward_component.recalculate_finals(action_data.extra_power_bonus)
	
	if cost_component:
		cost_component.configure(action_data)
		
	# --- Configure the notification so it knows its ID and can pulse! ---
	if notification_indicator_component:
		notification_indicator_component.configure(action_data.id, self)
		
	# 3. CRITICAL: Refresh the Visuals
	_update_ui()
	
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
	
	# ==========================================================================
	# 1. COSTS (Currency & Vitals) -> Uses .format_loss()
	# ==========================================================================
	var currency_costs = action_data.currency_costs
	var vital_costs = action_data.vital_costs
	
	if cost_component:
		currency_costs = cost_component.final_currency_costs
		vital_costs = cost_component.final_vital_costs

	# Add Currency Costs
	for type in currency_costs:
		var amount = currency_costs[type]
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0:
			text_lines.append(def.format_loss(amount)) 

	# Add Vital Costs
	for type in vital_costs:
		var amount = vital_costs[type]
		var def = VitalManager.get_definition(type)
		if def and amount > 0:
			text_lines.append(def.format_loss(amount))

	# ==========================================================================
	# 2. REWARDS (Currency & Vitals) -> Uses .format_gain()
	# ==========================================================================
	var currency_gains = action_data.currency_gains
	var vital_gains = action_data.vital_gains
	
	if reward_component:
		currency_gains = reward_component.final_currency_gains
		vital_gains = reward_component.final_vital_gains

	# Add Currency Rewards
	for type in currency_gains:
		var amount = currency_gains[type]
		var def = CurrencyManager.get_definition(type)
		if def and amount > 0:
			text_lines.append(def.format_gain(amount)) 

	# Add Vital Rewards
	for type in vital_gains:
		var amount = vital_gains[type]
		var def = VitalManager.get_definition(type)
		if def and amount > 0:
			text_lines.append(def.format_gain(amount)) 

	# ==========================================================================
	# 3. TIME COST (Effective calculated time)
	# ==========================================================================
	if action_data.effective_time_cost > 0:
		text_lines.append("[color=gray]Time: %d min[/color]" % int(action_data.effective_time_cost))

	# Apply all lines to the label
	stats_label.text = "[center]%s[/center]" % "\n".join(text_lines)


# ==============================================================================
# 7. UPGRADE LOGIC
# ==============================================================================
func _recalculate_upgrades() -> void:
	_load_data_into_components()

func _on_upgrade_leveled(id: String, _lvl: int) -> void:
	var is_relevant: bool = false
	
	# 1. Check local button overrides (if you still use these manually)
	if primary_upgrade and primary_upgrade.id == id:
		is_relevant = true
	else:
		for upg in contributing_upgrades:
			if upg and upg.id == id:
				is_relevant = true
				break
				
	# 2. THE NEW SYSTEM: Check if the upgrade targets this action
	if not is_relevant and action_data:
		var upgraded_item = ItemManager.find_item_by_id(id)
		if upgraded_item != null and upgraded_item.target_action == action_data:
			is_relevant = true
	
	if is_relevant:
		# This is the call that force-refreshes the labels and rewards!
		_load_data_into_components()
