class_name LevelableUpgrade extends Resource

# --- NEW SECTION: TYPE DEFINITION ---
enum UpgradeType {
	TOOL,       # Pickaxes, Generators (Show in Tool Shop)
	TECHNOLOGY, # Permanent Unlocks (Show in Tech Tree)
	CONSUMABLE  # Potions/Boosts (Optional future use)
}

@export_category("Identity")
@export var id: String = "upgrade_id_here"
@export var icon: Texture2D
@export var world_sprite: Texture2D
@export var upgrade_type: UpgradeType = UpgradeType.TOOL 
@export var display_name: String = "Upgrade Name"
@export var target_stat: GameEnums.StatType

@export_group("Audio")
@export var audio_on_use: AudioStream
@export var audio_on_purchase: AudioStream

@export_category("Costs")
@export var cost_currency: GameEnums.CurrencyType = GameEnums.CurrencyType.GOLD
@export var base_cost: float = 10.0
@export var cost_growth: float = 2.0 

@export_category("Effect")
@export var power_per_level: float = 1.0

@export_category("Progression")
@export var max_level: int = -1 
@export var next_tier: LevelableUpgrade

@export_category("Requirements")
@export var required_upgrade_id: String = ""
@export var required_level: int = 0
