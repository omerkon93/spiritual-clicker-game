class_name GameEnums

# --- IDs 0 to 99 ---
enum CurrencyType {
	NONE = 0,
	MONEY = 1,
	SPIRIT = 2
}

# --- IDs 100+ ---
# By setting the first item to 100, the rest follow automatically (101, 102...)
enum VitalType {
	NONE = 100, # Start here to avoid collision with Currency
	ENERGY,   # Becomes 101
	FULLNESS, # Becomes 102
	FOCUS,    # Becomes 103
	SANITY    # Becomes 104
}

# --- IDs 200+ ---
enum StatType {
	NONE = 200, # Optional: Start Stats at 200
	CLICK_POWER,
	CLICK_COOLDOWN,
	AUTO_PRODUCTION,
	CRIT_CHANCE
}
