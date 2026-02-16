extends Control

@onready var label: RichTextLabel = %RichTextLabel

# We store the log in memory so we can manipulate counts
# Format: [{ "text": "Purchased Pizza", "color": Color.WHITE, "count": 1 }]
var message_history: Array[Dictionary] = []
var max_history_lines: int = 50 # Keep memory usage low

func _ready():
	label.text = ""
	
	# Listen to signal
	if SignalBus.has_signal("message_logged"):
		SignalBus.message_logged.connect(_add_message)
	
	_add_message("System: Game Loaded.", Color.GRAY)

func _add_message(text: String, color: Color = Color.WHITE):
	# 1. CHECK FOR DUPLICATES
	# We only check the very first item (index 0) because that is the "most recent" one
	if not message_history.is_empty():
		var most_recent = message_history[0]
		
		# If text AND color match, just increment the counter
		if most_recent.text == text and most_recent.color == color:
			most_recent.count += 1
			_redraw_log() # Refresh the display
			return

	# 2. ADD NEW MESSAGE
	# We create a new dictionary for this message
	var new_entry = {
		"text": text,
		"color": color,
		"count": 1
	}
	
	# push_front adds it to index 0 (The Top)
	message_history.push_front(new_entry)
	
	# 3. CLEANUP OLD MESSAGES
	if message_history.size() > max_history_lines:
		message_history.pop_back() # Remove the oldest message
		
	_redraw_log()

func _redraw_log():
	var final_bbcode = ""
	
	# Loop through our data and build the string
	for msg in message_history:
		var display_text = msg.text
		
		# If the count is higher than 1, add the (xN) suffix
		if msg.count > 1:
			display_text += " (x%d)" % msg.count
		
		# Convert color to Hex for BBCode
		var hex = msg.color.to_html()
		
		# Append to the final string with a newline
		final_bbcode += "[color=#%s]%s[/color]\n" % [hex, display_text]
	
	label.text = final_bbcode
