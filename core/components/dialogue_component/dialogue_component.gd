extends Node
class_name DialogueComponent

# --- DATA ---
@export_category("Content")
@export var sequence: DialogueSequence

@export_category("Logic")
@export var dialogue_actions: Dictionary[String, ActionData] = {}

# --- DEPENDENCIES ---
@export var cost_component: CostComponent
@export var reward_component: RewardComponent

func _ready() -> void:
	# Auto-find children (Only the ones we actually need)
	if not cost_component: cost_component = get_node_or_null("CostComponent")
	if not reward_component: reward_component = get_node_or_null("RewardComponent")
	
	SignalBus.dialogue_action.connect(_on_dialogue_action)

# --- PUBLIC API ---
func start_dialogue() -> void:
	if sequence:
		DialogueManager.instance.start_dialogue(sequence)
	else:
		printerr("DialogueComponent: No sequence assigned!")

# --- INTERNAL LOGIC ---
func _on_dialogue_action(trigger_id: String) -> void:
	print("⚡ Signal Received by: ", get_parent().name, " | ID: ", trigger_id)
	if not dialogue_actions.has(trigger_id):
		return
		
	var data: ActionData = dialogue_actions[trigger_id]
	_execute_transaction(data)

func _execute_transaction(data: ActionData) -> void:
	# 1. Setup
	if cost_component: 
		cost_component.configure(data)
	else:
		printerr("❌ DialogueComponent: Missing CostComponent!")

	if reward_component: 
		reward_component.configure(data)
	else:
		printerr("❌ DialogueComponent: Missing RewardComponent! Cannot give gift.")
	
	# 2. Check Costs (Blocking Action)
	if cost_component and not cost_component.check_affordability():
		# Handle Failure: Directly emit to SignalBus (No component needed)
		var fail_msg = data.failure_messages.get(0, "Transaction Failed")
		SignalBus.message_logged.emit(fail_msg, Color.RED)
		return

	# 3. Process Transaction
	if cost_component: cost_component.pay_all()
	
	if reward_component: 
		print("💰 Attempting to deliver rewards...") # DEBUG PRINT
		var feedback = reward_component.deliver_rewards()
		_show_feedback(feedback)

func _show_feedback(events: Array[Dictionary]) -> void:
	for event in events:
		SignalBus.message_logged.emit(event.text, event.color)
