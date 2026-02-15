extends Button

@export var slot_id: int = 1

# We remove the _pressed signal here because the Menu handles it now!
# This avoids "double logic" issues.

func refresh_state(mode: int):
	var info = SaveManager.get_slot_metadata(slot_id)
	
	if mode == 0: # --- LOAD MODE ---
		if info.exists:
			text = "SLOT %d\nCONTINUE\n%s" % [slot_id, info.timestamp]
			disabled = false
		else:
			text = "SLOT %d\nNEW GAME\n[Empty]" % slot_id
			disabled = false

	else: # --- SAVE MODE ---
		if info.exists:
			text = "SLOT %d\nOVERWRITE\n%s" % [slot_id, info.timestamp]
			# Optional: make it look dangerous
			modulate = Color(1, 0.7, 0.7) 
		else:
			text = "SLOT %d\nSAVE HERE\n[Empty]" % slot_id
			modulate = Color(0.7, 1, 0.7)
