extends PanelContainer

# --- RESEARCH UI REFS ---
@export_group("Research UI")
@onready var research_section: VBoxContainer = %ResearchSection
@onready var research_title: Label = %TechTitleLabel
@onready var research_bar: ProgressBar = %ProgressBar
@onready var research_time: Label = %TimeRemainingLabel

# --- BILLS UI REFS ---
@export_group("Bills UI")
@onready var bills_section: VBoxContainer = %BillsSection
@onready var bill_list: VBoxContainer = %BillList

# State
var current_research_id: String = ""

func _ready() -> void:
	# Hide sections by default
	research_section.visible = false
	bills_section.visible = false
	
	# Connect RESEARCH Signals
	ResearchManager.research_started.connect(_on_research_started)
	ResearchManager.research_progressed.connect(_on_research_progressed)
	ResearchManager.research_finished.connect(_on_research_finished)
	
	# Connect SUBSCRIPTION Signals
	SubscriptionManager.subscription_added.connect(_on_subs_updated)
	SubscriptionManager.subscription_removed.connect(_on_subs_updated)
	SubscriptionManager.bill_paid.connect(_on_bill_paid)
	
	# Connect TIME (to update "Days Left" count)
	TimeManager.day_started.connect(_on_day_changed)
	
	# Initial UI Refresh
	_refresh_bills_ui()

# ==============================================================================
# SECTION A: RESEARCH
# ==============================================================================
func _on_research_started(item_id: String, duration: int) -> void:
	var item = ItemManager.find_item_by_id(item_id)
	if not item: return

	current_research_id = item_id
	research_title.text = "Researching: " + item.display_name
	
	research_bar.max_value = duration
	research_bar.value = 0
	
	research_section.visible = true
	_update_research_time(duration)

func _on_research_progressed(item_id: String, remaining: int) -> void:
	if item_id != current_research_id: return
	
	research_bar.value = research_bar.max_value - remaining
	_update_research_time(remaining)

func _on_research_finished(item_id: String) -> void:
	if item_id == current_research_id:
		research_section.visible = false
		current_research_id = ""

func _update_research_time(work_remaining: int) -> void:
	var speed = ResearchManager.get_global_research_speed()
	if speed <= 0: speed = 1.0 # Safety
	
	var real_minutes = work_remaining / speed
	var hours = floor(real_minutes / 60.0)
	var mins = int(real_minutes) % 60
	
	if hours > 0:
		research_time.text = "%dh %dm remaining" % [hours, mins]
	else:
		research_time.text = "%dm remaining" % mins
		
	if speed > 1.0:
		research_time.text += " (x%.1f)" % speed

# ==============================================================================
# SECTION B: BILLS
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
		bills_section.visible = false
		return
	
	bills_section.visible = true
	
	# 3. Populate List
	for id in subs:
		var data = subs[id]
		var item: SubscriptionItem = data.item
		var days_left = SubscriptionManager.get_days_until_due(id)
		
		_create_bill_row(item, days_left)

func _create_bill_row(item: SubscriptionItem, days_left: int) -> void:
	var row = HBoxContainer.new()
	
	# Name Label
	var name_lbl = Label.new()
	name_lbl.text = "• " + item.display_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Status Label
	var status_lbl = Label.new()
	
	if days_left <= 0:
		status_lbl.text = "DUE TODAY ($%s)" % item.cost_amount
		status_lbl.modulate = Color(1, 0.4, 0.4) # Red
	elif days_left <= 1:
		status_lbl.text = "Tomorrow ($%s)" % item.cost_amount
		status_lbl.modulate = Color(1, 0.8, 0.4) # Orange
	else:
		status_lbl.text = "%d days ($%s)" % [days_left, item.cost_amount]
		status_lbl.modulate = Color(0.7, 0.7, 0.7) # Gray
		
	row.add_child(name_lbl)
	row.add_child(status_lbl)
	
	bill_list.add_child(row)
