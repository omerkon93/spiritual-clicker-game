extends Node2D

@onready var tab_container: TabContainer = %TabContainer

func _ready() -> void:
	# Connect the signal so we know when the player switches tabs
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Optional: Force the game to start on the "Actions" tab (Index 1 based on your screenshot)
	# Index 0 = Settings, 1 = Actions, 2 = Shop
	tab_container.current_tab = 0

func _on_tab_changed(tab_index: int) -> void:
	# Get the actual node that was just opened (e.g., ShopPanel)
	var active_tab = tab_container.get_child(tab_index)
	
	# If the tab has an 'open' function (like ShopPanel does), run it!
	if active_tab.has_method("open"):
		active_tab.open()
		
	# Special case: If it's the ActionsMenu, maybe we want to refresh it?
	# (Usually ActionsPanel does this in _ready, so it might not be needed)
	if active_tab.has_method("refresh"): 
		active_tab.refresh()
