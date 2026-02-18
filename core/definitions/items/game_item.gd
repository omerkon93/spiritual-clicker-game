extends Resource
class_name GameItem

# --- ENUMS ---
enum ItemType {
	CONSUMABLE,
	UPGRADE,
	TECHNOLOGY,
	MATERIAL
}

# --- IDENTITY ---
@export_category("Identity")
@export var id: String = "item_id"
@export var display_name: String = "Item Name"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.CONSUMABLE

# --- COMPONENTS ---
@export_category("Logic")
@export var requirements: Array[Resource] = []
@export var effects: Array[Resource] = []

# --- RESEARCH SETTINGS (NEW) ---
@export_category("Research")
## Time in MINUTES required to unlock this technology. Only used if ItemType is TECHNOLOGY.
@export var research_duration_minutes: int = 60

# --- SPECIAL LOGIC ---
@export_group("Special")
@export var story_flag_reward: StoryFlag
@export var on_purchase_action: ActionData

# --- AUDIO ---
@export_group("Presentation")
@export var audio_on_purchase: AudioStream
