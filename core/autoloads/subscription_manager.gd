extends Node

# Signals for the UI to listen to
signal subscription_added(item: SubscriptionItem)
signal subscription_removed(id: String)
signal bill_paid(item: SubscriptionItem, amount: float)
signal payment_failed(item: SubscriptionItem)

# Stores active subs. Key = ID, Value = Dictionary
# Example: { "sub_rent": { "item": Resource, "next_due_day": 14 } }
var active_subscriptions: Dictionary = {}

func _ready() -> void:
	# Listen to the TimeManager for the day change
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)

# --- PUBLIC API ---

## Call this when the player signs a contract or rents an apartment
func subscribe(item: SubscriptionItem) -> void:
	if active_subscriptions.has(item.id): return
	
	# Calculate the first due date (Today + Interval)
	var due_day = TimeManager.current_day + item.interval_days
	
	active_subscriptions[item.id] = {
		"item": item,
		"next_due_day": due_day
	}
	
	subscription_added.emit(item)
	print("📅 Subscribed to %s. Next bill: Day %d" % [item.display_name, due_day])

func unsubscribe(id: String) -> void:
	if active_subscriptions.has(id):
		active_subscriptions.erase(id)
		subscription_removed.emit(id)
		print("❌ Unsubscribed from %s." % id)

func get_days_until_due(id: String) -> int:
	if not active_subscriptions.has(id): return -1
	var data = active_subscriptions[id]
	return data.next_due_day - TimeManager.current_day

# --- INTERNAL LOGIC ---

func _on_day_started(day: int) -> void:
	# Check every active subscription
	# We use .keys() so we can safely modify the dictionary while looping if needed
	for id in active_subscriptions.keys():
		var data = active_subscriptions[id]
		
		# Is it payday?
		if day >= data.next_due_day:
			_process_payment(id, data)

func _process_payment(id: String, data: Dictionary) -> void:
	var item: SubscriptionItem = data.item
	
	# 1. Check if player has money
	if CurrencyManager.has_enough_currency(item.currency_type, item.cost_amount):
		
		# 2. Pay
		CurrencyManager.spend_currency(item.currency_type, item.cost_amount)
		
		# 3. Renew or Cancel
		if item.auto_renew:
			data.next_due_day += item.interval_days
		else:
			unsubscribe(id)
			
		# 4. Notify System
		bill_paid.emit(item, item.cost_amount)
		SignalBus.message_logged.emit("Paid %s (-$%d)" % [item.display_name, item.cost_amount], Color.ORANGE)
		
	else:
		# 5. Handle Failure
		payment_failed.emit(item)
		SignalBus.message_logged.emit("MISSED PAYMENT: %s!" % item.display_name, Color.RED)
		
		# Trigger penalty if defined
		if item.penalty_flag != "":
			print("💀 Triggering Penalty: ", item.penalty_flag)
			# ProgressionManager.set_flag(item.penalty_flag, true)
