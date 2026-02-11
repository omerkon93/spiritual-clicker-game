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
	NONE = 100,
	ENERGY,
	FULLNESS,
	FOCUS,
	SANITY
}

# --- IDs 200+ ---
enum StatType {
	NONE = 200,
	CLICK_POWER,
	CLICK_COOLDOWN,
	AUTO_PRODUCTION,
	CRIT_CHANCE
}
