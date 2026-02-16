extends Resource
class_name ActionData

enum ActionCategory {
	## Player way to gain currency.
	CAREER,
	## Player way to recover vitals.
	SURVIVAL,
	## Player way to upgrade stuff.
	SPIRITUAL,
	OTHER
}

# --- IDENTITY ---
@export_category("Identity")

## Unique string identifier. Used for save data and database lookups.
@export var id: String = "action_id"

## The name shown to the player in the UI.
@export var display_name: String = "New Action"

## Determines which tab or section this action appears in.
@export var category: ActionCategory = ActionCategory.CAREER

## Flavour text describing the action to the player.
@export_multiline var description: String = ""

## The image displayed on the action button or card.
@export var icon: Texture2D

# --- SETTINGS ---
@export_category("Settings")

## If true, the player has this action available immediately.
@export var is_unlocked_by_default: bool = true 

## If false, this is hidden from the UI entirely (useful for hidden triggers).
@export var is_visible_in_menu: bool = true

@export_group("Time Settings")

## How much in-game time passes when performing this action.
@export var time_cost_minutes: int = 60 # Default 1 hour

## Multiplier for how long the progress bar takes in real-time.
@export var base_duration: float = 1.0 

@export_category("Requirements")

## Optional: A specific story flag required to unlock this action.
@export var required_story_flag: StoryFlag

# --- EVENTS ---
@export_category("Events")

## The ID of the global signal to emit when this action completes.
@export var trigger_signal_id: String = ""

# --- COSTS ---
@export_category("Costs")

## Vitals reduced by this action.
## [br]Key: VitalType, Value: Amount to decrease.
@export var vital_costs: Dictionary[VitalDefinition.VitalType, float] = {}

## Money or resources required to start this action.
@export var currency_costs: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

# --- REWARDS ---
@export_category("Rewards")

## Vitals restored/increased by this action.
@export var vital_gains: Dictionary[VitalDefinition.VitalType, float] = {}

## Money or resources earned upon completion.
@export var currency_gains: Dictionary[CurrencyDefinition.CurrencyType, float] = {}

# --- MESSAGES ---
@export_category("Messages")

## Custom error messages when specific requirements are not met.
## [br]Format: { VitalDefinition.VitalType.ENERGY: "You are too tired!" }
@export var failure_messages: Dictionary = {}
