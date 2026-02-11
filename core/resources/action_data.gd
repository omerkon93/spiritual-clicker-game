extends Resource
class_name ActionData

enum ActionCategory {
	CAREER,
	SURVIVAL,
	SPIRITUAL,
	OTHER
}

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "action_id"
@export var display_name: String = "New Action"
@export var category: ActionCategory = ActionCategory.CAREER
@export_multiline var description: String = ""
@export var icon: Texture2D

# --- SETTINGS ---
@export_category("Settings")
@export var base_duration: float = 1.0 
@export var is_unlocked_by_default: bool = true 
@export var is_visible_in_menu: bool = true

@export_group("Time Settings")
@export var time_cost_minutes: int = 60 # Default 1 hour

@export_category("Requirements")
@export var required_story_flag: String = "" 

# --- EVENTS ---
@export_category("Events")
@export var trigger_signal_id: String = ""

# --- COSTS ---
@export_category("Costs")
@export var vital_costs: Dictionary[GameEnums.VitalType, float] = {}
@export var currency_costs: Dictionary[GameEnums.CurrencyType, float] = {}

# --- REWARDS ---
@export_category("Rewards")
@export var vital_gains: Dictionary[GameEnums.VitalType, float] = {}
@export var currency_gains: Dictionary[GameEnums.CurrencyType, float] = {}

# --- MESSAGES ---
@export_category("Messages")
# Format: { GameEnums.VitalType.ENERGY: "Not enough energy!" }
@export var failure_messages: Dictionary = {}
