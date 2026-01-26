extends Label

func animate(start_pos: Vector2, value_text: String, color: Color):
	# 1. Setup Content
	text = value_text
	modulate = color
	
	# 2. Force the label to resize to fit the text perfectly immediately
	reset_size() 
	
	# 3. Center the label on the target position
	# (Position - Half Size = Centered)
	global_position = start_pos - (size / 2)
	
	# 4. Set pivot for the 'Pop' animation to the new center
	pivot_offset = size / 2 
	scale = Vector2.ZERO
	
	# --- Animation Logic (Same as before) ---
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "global_position:y", global_position.y - 60, 0.8)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
	tween.tween_property(self, "modulate:a", 0.0, 0.8)\
		.set_ease(Tween.EASE_IN)
		
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(queue_free)
