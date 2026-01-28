class_name ResourceConfig

# Define the "Look and Feel" for every ID here
const CONFIG: Dictionary = {
	# --- CURRENCIES ---
	GameEnums.CurrencyType.MONEY: {
		"name": "Money",
		"icon": "$", 
		"color": Color("#FFD700") # Gold
	},
	GameEnums.CurrencyType.SPIRIT: {
		"name": "Spirit",
		"icon": "Ψ",
		"color": Color("#9370DB") # Medium Purple
	},
	
	# --- VITALS ---
	GameEnums.VitalType.ENERGY: {
		"name": "Energy",
		"icon": "⚡", 
		"color": Color("#00BFFF") # Deep Sky Blue
	},
	GameEnums.VitalType.FULLNESS: {
		"name": "Fullness",
		"icon": "🍔", 
		"color": Color("#FFA500") # Orange
	},
	GameEnums.VitalType.FOCUS: {
		"name": "Focus",
		"icon": "👁", 
		"color": Color("#32CD32") # Lime Green
	},
	GameEnums.VitalType.SANITY: {
		"name": "Sanity",
		"icon": "🧠", 
		"color": Color("#FF69B4") # Hot Pink
	}
}

# --- PUBLIC HELPERS ---

static func get_color(id: int) -> Color:
	if CONFIG.has(id): return CONFIG[id]["color"]
	return Color.WHITE

static func get_name(id: int) -> String:
	if CONFIG.has(id): return CONFIG[id]["name"]
	return "Unknown"

static func get_icon(id: int) -> String:
	if CONFIG.has(id): return CONFIG[id]["icon"]
	return ""

# Format: "+10 ⚡" or "+$10"
static func format_gain(id: int, amount: float) -> String:
	var entry = CONFIG.get(id, {})
	var icon = entry.get("icon", "")
	
	# Special formatting for Money (Prefix)
	if id == GameEnums.CurrencyType.MONEY:
		return "+%s%s" % [icon, NumberFormatter.format_value(amount)]
	
	# Standard formatting for Vitals (Suffix)
	return "+%s %s" % [amount, icon]
