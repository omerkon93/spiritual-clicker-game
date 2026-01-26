class_name GameEnums

# Things you accumulate and spend
enum CurrencyType {
	NONE,
	MONEY,
	SPIRIT
}

# Things that keep you alive (0 to 100%)
enum VitalType {
	NONE,
	SANITY,
	ENERGY,   # For short term stamina
	HUNGER    # For survival mechanics
}

enum StatType {
	NONE,
	CLICK_POWER,       # The strength of the click
	CLICK_COOLDOWN,    # The delay (Replaces COOLDOWN_REDUCTION)
	AUTO_PRODUCTION,   # Passive income (for later)
	CRIT_CHANCE        # (for later)
}
