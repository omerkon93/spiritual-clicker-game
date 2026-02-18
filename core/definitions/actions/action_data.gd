extends Resource
class_name ActionData

enum ActionCategory { CAREER, SURVIVAL, SPIRITUAL, OTHER }

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "action_id"
@export var display_name: String = "New Action"
@export var category: ActionCategory = ActionCategory.CAREER
@export_multiline var description: String = ""
@export var icon: Texture2D

# --- SETTINGS ---
@export_category("Settings")
@export var is_unlocked_by_default: bool = true 
@export var is_visible_in_menu: bool = true

@export_group("Time Settings")
@export var time_cost_minutes: int = 60 
@export var base_duration: float = 1.0 

# --- REQUIREMENTS & UPGRADES ---
@export_category("Requirements")
@export var required_story_flag: StoryFlag

@export_group("Upgrades")
@export var contributing_items: Array[GameItem] = []

# --- EVENTS ---
@export_category("Events")
@export var trigger_signal_id: String = ""

# --- COSTS ---
@export_category("Costs")
@export var vital_costs: Dictionary[VitalDefinition.VitalType, float] = {}
@export var currency_costs: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

# --- REWARDS ---
@export_category("Rewards")
@export var vital_gains: Dictionary[VitalDefinition.VitalType, float] = {}
@export var currency_gains: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

# --- MESSAGES ---
@export_category("Messages")
@export var failure_messages: Dictionary = {}

# ==============================================================================
# RUNTIME VALUES
# ==============================================================================
var effective_cooldown: float = 0.0
var effective_time_cost: float = 0.0
var extra_power_bonus: float = 0.0

func recalculate_stats() -> void:
	# 1. Reset to Base values
	effective_cooldown = base_duration
	effective_time_cost = float(time_cost_minutes)
	extra_power_bonus = 0.0
	
	# Accumulators for multipliers and reductions
	var power_flat: float = 0.0
	var power_percent: float = 0.0
	var cooldown_reduction_flat: float = 0.0
	var cooldown_reduction_percent: float = 0.0
	var time_efficiency_mod: float = 0.0 # Stacks to reduce in-game minutes
	
	# 2. Iterate linked items (Guest List)
	for item in contributing_items:
		if item == null: continue
		
		var lvl = ProgressionManager.get_upgrade_level(item.id)
		if lvl <= 0: continue
		
		# Iterate through the NEW effects array instead of old power_per_level
		for effect in item.effects:
			if effect == null: continue
			
			# Check if this effect modifies a Stat
			if "stat" in effect and "amount" in effect:
				var amount = effect.amount * lvl
				var is_perc = effect.get("is_percentage") if "is_percentage" in effect else false
				
				match effect.stat:
					# --- POWER ---
					StatDefinition.StatType.ACTION_POWER, StatDefinition.StatType.AUTOMATION_EFFICIENCY:
						if is_perc: power_percent += amount
						else: power_flat += amount

					# --- EFFICIENCY (This reduces both button cooldown AND in-game time) ---
					StatDefinition.StatType.ACTION_EFFICIENCY:
						if is_perc:
							cooldown_reduction_percent += amount
							time_efficiency_mod += amount
						else:
							cooldown_reduction_flat += amount
							# For flat reduction in minutes, we can treat 1.0 as 1 minute
							time_efficiency_mod += (amount / 60.0) 

	# 3. Final Math
	
	# POWER CALCULATION
	# Apply percentages to the Action's base reward
	var base_reward: float = 0.0
	if not currency_gains.is_empty():
		base_reward = currency_gains.values()[0] # Grabs Money or Spirit
		
	# Result: (Base * %Boost) + (Flat * (1 + %Boost))
	extra_power_bonus = (base_reward * power_percent) + (power_flat * (1.0 + power_percent))

	# COOLDOWN CALCULATION (Real-time button reset)
	var cd_after_flat = max(0.1, base_duration - cooldown_reduction_flat)
	effective_cooldown = max(0.1, cd_after_flat * (1.0 - cooldown_reduction_percent))
	
	# TIME COST CALCULATION (In-game minutes)
	# Logic: 0.1 efficiency means 10% faster (90% of the time cost)
	var final_time_mult = max(0.1, 1.0 - time_efficiency_mod)
	effective_time_cost = float(time_cost_minutes) * final_time_mult
