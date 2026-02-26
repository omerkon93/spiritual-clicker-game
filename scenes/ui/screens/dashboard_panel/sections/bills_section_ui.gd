extends VBoxContainer
class_name BillsSectionUI

# --- NODES ---
@onready var bill_list: VBoxContainer = $BillList

func _ready() -> void:
	hide() # Hidden by default if empty
	
	SubscriptionManager.subscription_added.connect(_on_subs_updated)
	SubscriptionManager.subscription_removed.connect(_on_subs_updated)
	SubscriptionManager.bill_paid.connect(_on_bill_paid)
	TimeManager.day_started.connect(_on_day_changed)
	
	_refresh_bills_ui()

# ==============================================================================
# LOGIC
# ==============================================================================
func _on_subs_updated(_arg = null) -> void:
	_refresh_bills_ui()

func _on_bill_paid(_item, _amt) -> void:
	_refresh_bills_ui()

func _on_day_changed(_day) -> void:
	_refresh_bills_ui()

func _refresh_bills_ui() -> void:
	# 1. Clear List
	for child in bill_list.get_children():
		child.queue_free()
	
	var subs = SubscriptionManager.active_subscriptions
	
	# 2. Hide section if empty
	if subs.is_empty():
		hide()
		return
	
	show()
	
	# 3. Populate List
	for id in subs:
		var data = subs[id]
		var item: SubscriptionItem = data.item
		var days_left = SubscriptionManager.get_days_until_due(id)
		
		_create_bill_row(item, days_left)

func _create_bill_row(item: SubscriptionItem, days_left: int) -> void:
	var row = HBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = "• " + item.display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var status_lbl = Label.new()
	
	if days_left <= 0:
		status_lbl.text = "DUE TODAY ($%s)" % item.cost_amount
		status_lbl.modulate = Color(1, 0.4, 0.4) 
	elif days_left <= 1:
		status_lbl.text = "Tomorrow ($%s)" % item.cost_amount
		status_lbl.modulate = Color(1, 0.8, 0.4) 
	else:
		status_lbl.text = "%d days ($%s)" % [days_left, item.cost_amount]
		status_lbl.modulate = Color(0.7, 0.7, 0.7) 
		
	row.add_child(name_lbl)
	row.add_child(status_lbl)
	
	bill_list.add_child(row)
