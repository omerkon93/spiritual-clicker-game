extends Button
class_name ShopItemButton

# The Setter ensures UI updates whenever data changes
@export var upgrade_resource: GameItem :
	set(value):
		upgrade_resource = value
		if is_node_ready(): 
			_update_label()
			_update_display()

# Visual colors
var color_affordable: Color = Color.WHITE
var color_expensive: Color = Color(1, 0.4, 0.4, 1.0)
var color_owned: Color = Color(0.5, 1.0, 0.5, 1.0) 

@onready var notification_indicator_component: NotificationIndicatorComponent = $NotificationIndicatorComponent

func _ready() -> void:
	pressed.connect(_on_pressed)
	ProgressionManager.upgrade_leveled_up.connect(_on_level_changed)
	CurrencyManager.currency_changed.connect(_on_currency_changed)
	
	custom_minimum_size = Vector2(240, 80) # Taller for more text
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	if upgrade_resource:
		_update_label()
		_update_display()
	else:
		text = "Loading..."

func _on_pressed() -> void:
	if not upgrade_resource: return
	if notification_indicator_component: notification_indicator_component.mark_as_seen()
	
	if ItemManager.try_purchase_item(upgrade_resource):
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(self, "scale", Vector2.ONE, 0.05)
		_update_label()

func _on_level_changed(changed_id: String, _new_lvl: int) -> void:
	if upgrade_resource and upgrade_resource.id == changed_id:
		_update_label()
		_update_display()

func _on_currency_changed(_type: int, _new_amount: float) -> void:
	_update_label()

func _update_label() -> void:
	if upgrade_resource == null: 
		text = "Loading..."
		return
	
	# 1. OWNERSHIP
	var current_lvl = ProgressionManager.get_upgrade_level(upgrade_resource.id)
	if upgrade_resource.item_type != GameItem.ItemType.CONSUMABLE and current_lvl >= 1:
		text = "%s\n(Owned)" % upgrade_resource.display_name
		modulate = color_owned
		disabled = true
		return
		
	# 2. COSTS
	var cost_strings = []
	var can_afford_all = true
	for req in upgrade_resource.requirements:
		if req.has_method("is_met") and not req.is_met(): can_afford_all = false
		if req.has_method("get_cost_text"): cost_strings.append(req.get_cost_text())
	
	var cost_text = "Free"
	if cost_strings.size() > 0: cost_text = " + ".join(cost_strings)
	
	# 3. EFFECTS TEXT (New!)
	var effects_text = _get_effects_text()

	# 4. FINAL DISPLAY
	# If there are no effects (e.g. flavor item), just show name and cost
	if effects_text == "":
		text = "%s\n%s" % [upgrade_resource.display_name, cost_text]
	else:
		text = "%s\n%s\n%s" % [upgrade_resource.display_name, effects_text, cost_text]
	
	modulate = color_affordable if can_afford_all else color_expensive

func _update_display() -> void:
	if not upgrade_resource: return
	if upgrade_resource.icon: icon = upgrade_resource.icon
	if notification_indicator_component:
		notification_indicator_component.configure(upgrade_resource.id, self)

# --- EXPANDED HELPER ---
func _get_effects_text() -> String:
	var parts = []
	
	# -------------------------------------------------------------
	# 1. RESEARCH TIME (New Feature)
	# -------------------------------------------------------------
	if upgrade_resource.item_type == GameItem.ItemType.TECHNOLOGY:
		var base_time = upgrade_resource.research_duration_minutes
		
		# Get the player's current speed multiplier
		# Ensure ResearchManager.get_global_research_speed() is public (no underscore)
		var speed = ResearchManager.get_global_research_speed()
		
		# Calculate effective time (Work / Speed)
		var effective_time = int(base_time / speed)
		
		# Format time nicely (e.g., "1h 30m" or just "45m")
		var time_str = ""
		var hours = floor(effective_time / 60.0)
		var mins = int(effective_time) % 60
		
		if hours > 0:
			time_str = "%dh %dm" % [hours, mins]
		else:
			time_str = "%dm" % mins
			
		parts.append("Research Time: %s" % time_str)

	# -------------------------------------------------------------
	# 2. STAT EFFECTS (Existing Logic)
	# -------------------------------------------------------------
	for effect in upgrade_resource.effects:
		if "stat" in effect and "amount" in effect:
			var amount = effect.amount
			# Safe Key Lookup
			var stat_key = StatDefinition.StatType.find_key(effect.stat)
			var stat_name = stat_key.capitalize() if stat_key else "Stat"
			
			if "is_percentage" in effect and effect.is_percentage:
				# 0.1 -> "+10%"
				var permil = int(amount * 100)
				var sign_str = "+" if permil >= 0 else ""
				parts.append("%s%d%% %s" % [sign_str, permil, stat_name])
			else:
				# 10 -> "+10"
				var sign_str = "+" if amount >= 0 else ""
				var val_str = str(int(amount)) if is_equal_approx(amount, round(amount)) else "%.1f" % amount
				parts.append("%s%s %s" % [sign_str, val_str, stat_name])

	# -------------------------------------------------------------
	# 3. STORY FLAGS (Technology / Unlocks)
	# -------------------------------------------------------------
	if upgrade_resource.story_flag_reward:
		var flag = upgrade_resource.story_flag_reward
		var label = "New Feature"
		
		# Try to find a human-readable name
		if "display_name" in flag and flag.display_name != "":
			label = flag.display_name
		elif "id" in flag and flag.id != "":
			label = flag.id.capitalize().replace("_", " ")
			
		parts.append("Unlocks: %s" % label)

	# -------------------------------------------------------------
	# 4. ACTION REWARDS (Consumables)
	# -------------------------------------------------------------
	if upgrade_resource.on_purchase_action:
		var action = upgrade_resource.on_purchase_action
		
		# A. Vitals (e.g. Restores Energy)
		for type in action.vital_gains:
			var amount = action.vital_gains[type]
			if amount > 0:
				var v_key = VitalDefinition.VitalType.find_key(type)
				var v_name = v_key.capitalize() if v_key else "Vital"
				parts.append("Restores %d %s" % [int(amount), v_name])
				
		# B. Currency (e.g. Gives Money)
		for type in action.currency_gains:
			var amount = action.currency_gains[type]
			if amount > 0:
				if type == CurrencyDefinition.CurrencyType.MONEY:
					parts.append("Gives $%d" % int(amount))
				else:
					var c_key = CurrencyDefinition.CurrencyType.find_key(type)
					var c_name = c_key.capitalize() if c_key else "Currency"
					parts.append("Gives %d %s" % [int(amount), c_name])

	return "\n".join(parts)
