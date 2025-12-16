class_name TimerSettingsUI extends PanelContainer

enum DIRECTIONS {MINUP = 0, MINDOWN = 1, SECUP = 2, SECDOWN = 3}

# This determines which timer is affected by these settings and what name is displayed.
@export var timer_type : Enums.PHASES

var minutes_setting : int = 0
var seconds_setting : int = 0

signal timer_settings_changed(type: Enums.PHASES, settings: Vector2i)

# References to all the buttons and labels needed.
@onready var minutes_bigup = get_node("VBoxContainer/TimerSet/MinutesSettings/Up/BigUp")
@onready var minutes_smallup = get_node("VBoxContainer/TimerSet/MinutesSettings/Up/SmallUp")
@onready var minutes_bigdown = get_node("VBoxContainer/TimerSet/MinutesSettings/Down/BigDown")
@onready var minutes_smalldown = get_node("VBoxContainer/TimerSet/MinutesSettings/Down/SmallDown")
@onready var minutes_display = get_node("VBoxContainer/TimerSet/MinutesSettings/Value")

@onready var seconds_bigup = get_node("VBoxContainer/TimerSet/SecondsSettings/Up/BigUp")
@onready var seconds_smallup = get_node("VBoxContainer/TimerSet/SecondsSettings/Up/SmallUp")
@onready var seconds_bigdown = get_node("VBoxContainer/TimerSet/SecondsSettings/Down/BigDown")
@onready var seconds_smalldown = get_node("VBoxContainer/TimerSet/SecondsSettings/Down/SmallDown")
@onready var seconds_display = get_node("VBoxContainer/TimerSet/SecondsSettings/Value")

# Label that holds the name of the timer this node is to affect. Set in _ready()
@onready var timer_name = get_node("VBoxContainer/PhaseName")

# Set the name label according to which timer this node represents.
func _ready() -> void:
	match timer_type:
		Enums.PHASES.FOCUS: timer_name.text = "Focus Timer"
		Enums.PHASES.SHORT_PAUSE: timer_name.text = "Short Break Timer"
		Enums.PHASES.LONG_PAUSE: timer_name.text = "Long Break Timer"


# Updates the UI each time a settings value is changed due to a button press.
# The main task of this function is to ensure respective buttons are disabled whenever
# pressing them would cause a breach from the following hardcoded boundaries:
# Minutes: 0-120, Seconds: 0-59
# It also updates the displays of the minutes and seconds labels.
func update_ui(type: DIRECTIONS):
	minutes_display.text = str("%02d" % minutes_setting)
	seconds_display.text = str("%02d" % seconds_setting)
	match type:
		DIRECTIONS.MINUP:
			if minutes_setting >= 120: minutes_smallup.disabled = true
			if minutes_setting >= 111: minutes_bigup.disabled = true
			if minutes_setting >= 10: minutes_bigdown.disabled = false
			if minutes_setting >= 1: minutes_smalldown.disabled = false
		DIRECTIONS.MINDOWN:
			if minutes_setting <= 0: minutes_smalldown.disabled = true
			if minutes_setting <= 9: minutes_bigdown.disabled = true
			if minutes_setting <= 120: minutes_smallup.disabled = false
			if minutes_setting <= 110: minutes_bigup.disabled = false
		DIRECTIONS.SECUP:
			if seconds_setting >= 59: seconds_smallup.disabled = true
			if seconds_setting >= 50: seconds_bigup.disabled = true
			if seconds_setting >= 10: seconds_bigdown.disabled = false
			if seconds_setting >= 1: seconds_smalldown.disabled = false
		DIRECTIONS.SECDOWN:
			if seconds_setting <= 0: seconds_smalldown.disabled = true
			if seconds_setting <= 9: seconds_bigdown.disabled = true
			if seconds_setting <= 58: seconds_smallup.disabled = false
			if seconds_setting <= 49: seconds_bigup.disabled = false
# Each of these small functions is linked to the respective signal of the button.
# It does the operation of the button, then calls for the UI to be updated.
# For Minutes and Seconds each there are "small" (+/-1) and "big" (+/-10) buttons.

func min_smallup():
		minutes_setting += 1
		update_ui(DIRECTIONS.MINUP)

func min_bigup():
		minutes_setting += 10
		update_ui(DIRECTIONS.MINUP)

func min_smalldown():
		minutes_setting -= 1
		update_ui(DIRECTIONS.MINDOWN)

func min_bigdown():
		minutes_setting -= 10
		update_ui(DIRECTIONS.MINDOWN)


func sec_smallup():
		seconds_setting += 1
		update_ui(DIRECTIONS.SECUP)

func sec_bigup():
		seconds_setting += 10
		update_ui(DIRECTIONS.SECUP)

func sec_smalldown():
		seconds_setting -= 1
		update_ui(DIRECTIONS.SECDOWN)

func sec_bigdown():
		seconds_setting -= 10
		update_ui(DIRECTIONS.SECDOWN)

# Called upon the apply button being pressed. It emits a signal that passes the relevant information
# to the Game Screen Manager which then sets the respective timer.
func _apply_timer_settings() -> void:
	timer_settings_changed.emit(timer_type, Vector2i(minutes_setting, seconds_setting))
