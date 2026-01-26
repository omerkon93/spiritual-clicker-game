extends Button

@export var upgrade_resource: LevelableUpgrade


func _ready():
	pressed.connect(_on_pressed)
	
	# Listen for changes from the Manager (e.g., when Loading)
	UpgradeManager.upgrade_leveled_up.connect(_on_level_changed)
	
	# Force the icon to behave
	expand_icon = true
	
	# Set alignment (Horizontal alignment of the icon)
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Force a specific pixel size (e.g., 64px)
	add_theme_constant_override("icon_max_width", 32) 
	
	_update_label()
	_update_display()

func _on_pressed():
	# We don't need to update label here anymore, 
	# because the signal below will trigger it automatically!
	UpgradeManager.try_purchase_level(upgrade_resource)

func _on_level_changed(changed_id: String, _new_lvl: int):
	# 1. Check if this signal is for ME
	if upgrade_resource and upgrade_resource.id == changed_id:
		
		# Update the visuals
		_update_label()
		_update_display() 
		
		# 2. Play the Success Sound! (NEW)
		# (Check if the sound exists to avoid errors)
		if upgrade_resource.audio_on_purchase:
			# Play with a slightly higher pitch (1.1) to sound "positive"
			SoundManager.play_sfx(upgrade_resource.audio_on_purchase, 1.1, 0.05)

func _update_label():
	if upgrade_resource == null: return
	
	var cost = UpgradeManager.get_current_cost(upgrade_resource)
	var current_lvl = UpgradeManager.get_upgrade_level(upgrade_resource.id)
	
	# CHANGE: Use the new NumberFormatter class
	var cost_str = NumberFormatter.format_value(cost)
	
	text = "%s (Lvl %d)\nCost: %s Gold" % [
		upgrade_resource.display_name, 
		current_lvl, 
		cost_str # <--- Clean string!
	]

func _update_display():
	if not upgrade_resource: return
	
	# 1. Update Text (Your existing logic)
	_update_label() 
	
	# 2. Update Icon (NEW)
	if upgrade_resource.icon:
		icon = upgrade_resource.icon
