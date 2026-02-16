extends Resource
class_name GameItem

# --- ENUMS ---
enum ItemType {
	TOOL,       # Pickaxes, Generators
	TECHNOLOGY, # Passive trees
	CONSUMABLE  # One-Time items (Apples, Potions)
}

# --- IDENTITY ---
@export_category("Identity")

## Unique identifier used for saving and referencing this item.
@export var id: String = "item_id"

## The name displayed to the player in the shop or inventory.
@export var display_name: String = "Item Name"

## Flavour text and details about the item's effect.
@export_multiline var description: String = ""

## The visual representation of the item.
@export var icon: Texture2D

## Defines how the item behaves (e.g., equipment vs. one-time use).
@export var item_type: ItemType = ItemType.TOOL

# --- SETTINGS ---
@export_category("Settings")

# --- ACTION LINKING ---
@export_group("Action Link")

## The ActionData resource that gets triggered or modified when this item is bought/used.
@export var on_purchase_action: ActionData

## The specific stat this item modifies (if applicable).
## [br]Use 'NONE' if this item doesn't directly boost a stat.
@export var target_stat: StatDefinition.StatType = StatDefinition.StatType.NONE

## How much the target stat increases for every level of this item.
@export var power_per_level: float = 1.0

# --- COSTS ---
@export_group("Costs")

## The type of currency required to purchase or upgrade this item.
@export var cost_currency: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.MONEY

## The initial cost to purchase level 1 of this item.
@export var base_cost: float = 10.0

## The rate at which the cost increases per level.
## [br]Formula: Cost = BaseCost * (Multiplier ^ Level)
@export var cost_multiplier: float = 1.0

# --- PROGRESSION ---
@export_group("Progression")

## Optional: A specific story milestone required before this item becomes visible or purchasable.
@export var required_story_flag: StoryFlag

## Optional: Another item that must be owned (or maxed) before this one unlocks.
## [br]Useful for tech trees (e.g., Wooden Pickaxe -> Stone Pickaxe).
@export var required_item: GameItem

## The maximum level this item can be upgraded to.
## [br]Set to 1 for non-upgradable items.
@export var max_level: int = 1

## Optional: A Story Flag to set to TRUE immediately upon purchasing this item.
## [br]Useful for "Key Items" that unlock new areas or dialogue.
@export var story_flag_reward: StoryFlag

# --- REWARDS ---
@export_group("Rewards")
## Currency given to the player immediately upon unlocking this item (e.g., a "cashback" bonus).
@export var unlock_currency: CurrencyDefinition.CurrencyType = CurrencyDefinition.CurrencyType.NONE

## The amount of currency awarded.
@export var unlock_amount: float = 0.0

# --- AUDIO ---
@export_group("Audio")

## Sound effect played when the item is successfully purchased or upgraded.
@export var audio_on_purchase: AudioStream
