class_name PhaseTimer extends Node

# This node wraps a godot timer to create a good interface for this game's phase mechanics etc.

@onready var counter = get_node("Counter")
@export var set_minutes : int = 0
@export var set_seconds : int = 0


@export var phase : Enums.PHASES
var half_time : int
# this is defaulted to true to prevent plants which were saved as watered in the pause phase loading as "grown" when that save state is loaded in (signal won't be emitted)
var half_time_done : bool = true 

# saved for berry reward. no cheating by upping the timer settings after the phase started :)
var minutes_at_start

signal phase_over(phase : Enums.PHASES)
signal half_time_over()

# Currently remaining minutes.
var cur_minutes: int: 
	get: return int(counter.get_time_left()) / 60 if counter.get_time_left() > 0 else 0 # Integer division intended
# Currently remaining seconds.
var cur_seconds: int: 
	get: return int(counter.get_time_left()) % 60 if counter.get_time_left() > 0 else 0 

# Start the timer with the settings it has at this very moment.
# The half time is determined to trigger the signal at the appropriate time.
func start_timer() -> void:
	half_time = (set_minutes*60 + set_seconds)/2 # Integer division intended
	half_time_done = false
	minutes_at_start = set_minutes
	counter.set_wait_time(set_minutes*60 + set_seconds)
	counter.start()

# Set the timer's minute and second field to the given values.
# This method does NOT check if the arguments are valid, as input filtering is expected to be handled by UI.
# The setting does not affect the timer if it is currently running, and will only apply once the timer is restarted.
func set_timer(minutes: int, seconds: int) -> void:
	set_minutes = minutes
	set_seconds = seconds

# Returns the timer settings as a 2d int vector, where x is the minutes and y is the seconds.
func get_settings() -> Vector2i:
	return Vector2i(set_minutes, set_seconds)

# Toggles whether the timer is paused or not.
func toggle_pause_timer() -> void:
	counter.set_paused(!counter.is_paused())

# Private.
# Called when the timer node emits it's timeout signal.
func _on_counter_timeout() -> void:
	phase_over.emit(phase)

# Sets the timer to 0 seconds left.
func skip_timer() -> void:
	counter.stop() 
	counter.set_wait_time(1)
	counter.start()


# Private.
# Runs every physics frame (same as the timer itself) to check if the half time signal should be emitted.
# The half_time_done field is set to ensure it is emitted only once.
func _physics_process(_delta) -> void:
	if (counter.time_left <= half_time) && !half_time_done:
		half_time_done = true 
		half_time_over.emit()
