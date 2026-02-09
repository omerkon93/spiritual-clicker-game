extends Resource
class_name LevelableUpgrade

# --- ENUMS (Must be at the top) ---
enum UpgradeType {
	TOOL,       # Pickaxes, Generators
	TECHNOLOGY, # Passive trees
	CONSUMABLE  # Use this for One-Time items
}

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "upgrade_id"
@export var display_name: String = "Upgrade Name"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var world_sprite: Texture2D

# --- ACTION LINKING  ---
@export_category("Action Link")
@export var on_purchase_action: ActionData

# --- SETTINGS ---
@export_category("Settings")
@export var upgrade_type: UpgradeType = UpgradeType.TOOL
@export var target_stat: GameEnums.StatType = GameEnums.StatType.NONE
@export var power_per_level: float = 1.0

# --- COSTS ---
@export_category("Costs")
@export var cost_currency: GameEnums.CurrencyType = GameEnums.CurrencyType.MONEY
@export var base_cost: float = 10.0
@export var cost_multiplier: float = 2.0

# --- REWARD ---
@export_category("One-Time Reward")
@export var unlock_currency: GameEnums.CurrencyType = GameEnums.CurrencyType.NONE
@export var unlock_amount: float = 0.0

# --- AUDIO ---
@export_category("Audio")
@export var audio_on_use: AudioStream
@export var audio_on_purchase: AudioStream

# --- PROGRESSION ---
@export_category("Progression")
@export var max_level: int = -1 
@export var next_tier: LevelableUpgrade
@export var required_upgrade_id: String = ""
@export var required_level: int = 0
@export var required_story_flag: String = ""
