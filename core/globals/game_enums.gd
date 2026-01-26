class_name GameEnums

enum CurrencyType {
	NONE,
	MONEY,
	SPIRIT   # Reserve this for later (Phase 2)
}

enum StatType {
	NONE,
	CLICK_POWER,       # The strength of the click
	CLICK_COOLDOWN,    # The delay (Replaces COOLDOWN_REDUCTION)
	AUTO_PRODUCTION,   # Passive income (for later)
	CRIT_CHANCE        # (for later)
}
