class_name NumberFormatter

# The list of suffixes. You can extend this as far as you want!
# k = Thousand, M = Million, B = Billion, T = Trillion, q = Quadrillion...
const SUFFIXES = ["", "k", "M", "B", "T", "aa", "ab", "ac", "ad", "ae"]

static func format_value(value: float) -> String:
	# 1. Handle small numbers (0 to 999)
	# We snap to 1 decimal place (e.g., 10.5) but if it's whole, display as integer
	if value < 1000:
		if value < 10:
			# For very small numbers, show 1 decimal (e.g. 1.5)
			return str(snapped(value, 0.1))
		else:
			# For 10+, just show integer (e.g. 10, 999)
			return str(int(value))
			
	# 2. Loop to find the correct suffix
	var suffix_index = 0
	var temp_value = value
	
	# While the number is bigger than 1000, divide it and move to next suffix
	while temp_value >= 1000 and suffix_index < SUFFIXES.size() - 1:
		temp_value /= 1000.0
		suffix_index += 1
		
	# 3. Format the final string
	# %.2f means "2 decimal places" (e.g. 1.25 M)
	# We use step_decimals to avoid messy rounding errors
	var final_string = "%.2f" % temp_value
	
	# Optional: Trim trailing zeros (changes "1.50k" to "1.5k")
	if final_string.ends_with("0"):
		final_string = final_string.left(-1)
	if final_string.ends_with("0"):
		final_string = final_string.left(-1)
	if final_string.ends_with("."):
		final_string = final_string.left(-1)
		
	return final_string + SUFFIXES[suffix_index]
