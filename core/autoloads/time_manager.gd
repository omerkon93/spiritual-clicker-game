extends Node

signal time_updated(day: int, hour: int, minute: int)
signal day_started(day: int)
signal night_started(day: int)
# NEW: Signal to tell ResearchManager how much time passed
signal time_advanced(minutes: int) 

# Constants
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const NIGHT_START_HOUR = 20
const DAY_START_HOUR = 6

# State
var current_day: int = 1
var current_hour: int = 8
var current_minute: int = 0

func advance_time(minutes_to_add: int) -> void:
	current_minute += minutes_to_add
	
	# Emit the delta for Research Manager
	time_advanced.emit(minutes_to_add)
	
	# Handle Hour Rollover
	while current_minute >= MINUTES_PER_HOUR:
		current_minute -= MINUTES_PER_HOUR
		current_hour += 1
		
		# Handle Day Rollover
		if current_hour >= HOURS_PER_DAY:
			current_hour -= HOURS_PER_DAY
			current_day += 1
			day_started.emit(current_day)
			print("New Day Started: Day ", current_day)

	if current_hour == NIGHT_START_HOUR and current_minute == 0:
		night_started.emit(current_day)
		
	time_updated.emit(current_day, current_hour, current_minute)

func get_time_string() -> String:
	var period = "AM"
	var display_hour = current_hour
	if current_hour >= 12:
		period = "PM"
		if current_hour > 12: display_hour -= 12
	if display_hour == 0: display_hour = 12
	return "%02d:%02d %s" % [display_hour, current_minute, period]
