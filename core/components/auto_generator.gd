class_name AutoGenerator extends Node

@export_group("Settings")
@export var currency_type: GameEnums.CurrencyType = GameEnums.CurrencyType.MONEY
@export var cycle_time: float = 1.0
@export var auto_start: bool = true

@export_group("Stats")
@export var stat_def: StatDefinition

# CHANGE 1: Rename 'upgrade_def' to 'contributing_upgrades' and make it an Array
# This fixes the type mismatch error.
@export var contributing_upgrades: Array[GameItem] = []

var _timer: Timer

func _ready():
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = cycle_time
	_timer.one_shot = false
	_timer.timeout.connect(_on_timeout)
	
	if auto_start:
		start_generator()

func start_generator():
	_timer.start()

func stop_generator():
	_timer.stop()

func _on_timeout():
	if not stat_def: return

	# CHANGE 2: Pass the Array (contributing_upgrades) instead of the single var
	var amount = GameStatsManager.get_stat_value(stat_def, contributing_upgrades)
	
	if amount <= 0: return

	CurrencyManager.add_currency(currency_type, amount)
	
	# Visual Logic
	var parent_node = get_parent()
	var spawn_pos = Vector2.ZERO
	
	if parent_node is Control:
		spawn_pos = parent_node.global_position + (parent_node.size / 2)
	elif parent_node is Node2D:
		spawn_pos = parent_node.global_position
		
	var text_str = "+" + str(snapped(amount, 0.1))
	SignalBus.request_floating_text.emit(spawn_pos, text_str, Color.MAGENTA)
