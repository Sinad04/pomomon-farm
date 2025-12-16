extends CanvasLayer

# This node manages the UI elements of the game screen, in particular dynamic updates of displayed values or listening for button click events.

@onready var time_label = get_node("TimeDisplay/HBoxContainer/MarginContTimer/VBoxContainer/CurrentTime")
@onready var phase_label = get_node("TimeDisplay/HBoxContainer/MarginContTimer/VBoxContainer/CurrentPhase")
@onready var season_label = get_node("TimeDisplay/HBoxContainer/MarginContSeason/VBoxContainer/Season")
@onready var pause_button = get_node("TimeDisplay/HBoxContainer/MarginContPause/PauseTimer")
@onready var move_on_button = get_node("MoveOnDisplay/MarginContainer/MoveOnButton")
@onready var owned_berries_label = get_node("BerryDisplay/MarginContainer/OwnedBerries")

@onready var remaining_focuses_label = get_node("TimeDisplay/HBoxContainer/MarginContSeason/VBoxContainer/RemainingFocuses")

@onready var save_game_button = get_node("GameSettings/VBoxContainer/StateSettings/SaveGame")

@onready var seed_slots = [get_node("SeedInventory/MarginContainer/VBoxContainer/SeedSlotA"), 
get_node("SeedInventory/MarginContainer/VBoxContainer/SeedSlotB"), 
get_node("SeedInventory/MarginContainer/VBoxContainer/SeedSlotC")]

@onready var seed_shop = get_node("SeedShop")
@onready var seed_listings = [get_node("SeedShop/MarginContainer/VBoxContainer/SeedListingA"),
get_node("SeedShop/MarginContainer/VBoxContainer/SeedListingB"),
get_node("SeedShop/MarginContainer/VBoxContainer/SeedListingC")]

@onready var tile_listing = get_node("SeedShop/MarginContainer/VBoxContainer/TileListing")

# The button group instance that the three action selection buttons use.
@onready var action_button_group = preload("res://resources/action_button_group.tres") 
# The button group instance that the seed slots' "select" buttons in the seed inventory use.
@onready var select_seed_button_group = preload("res://resources/select_seed_button_group.tres")

@onready var audio = get_node("/root/ScreenManager/AudioManager")

# The timer of the currently active phase is the "tracked timer". The value of this timer is shown in the timer display.
var tracked_timer : PhaseTimer
@onready var owned_berries : int: 
	get: return get_parent().owned_berry_amount
@onready var owned_seeds : Array:
	get: return get_parent().owned_seed_amount

@onready var game_screen:
	get: return get_parent()

# Apply configuration to seed inventory slot names.
func _ready() -> void:
	# Place names in seed slots and shop listings according to config or default names instead.
	for i in range(3):
		seed_slots[i].get_name_label().text = Configuration.seeds[i]["name"] if Configuration.seeds.size() > i else "Nameless Seed"
		seed_listings[i].get_name_label().text = Configuration.seeds[i]["name"] if Configuration.seeds.size() > i else "Nameless Seed"
		if Configuration.seeds.size() > i:
			seed_listings[i].price = Configuration.seeds[i]["seedCost"] 
			seed_listings[i].get_price_label().text = "For " + str(Configuration.seeds[i]["seedCost"]) + " Berries."
		else:
			seed_listings[i].price = 0
			seed_listings[i].get_price_label().text = "For free."
		var fav_seasons_str = "None"
		if Configuration.seeds.size() > i:
			for season in Configuration.seeds[i]["favoredSeasons"]:
				if fav_seasons_str == "None": fav_seasons_str = ""
				fav_seasons_str += " " + season
		if Configuration.seeds.size() > i:
			seed_listings[i].get_desc_label().text = "Yield: " + str(Configuration.seeds[i]["harvestYield"]) + ", Time to Grow: " + str(Configuration.seeds[i]["growthStages"]) + ", Favored Season(s):" + fav_seasons_str

# Return the UI timer settings element as specified.
func get_timer_settings(type: Enums.PHASES):
	match type:
		Enums.PHASES.FOCUS: return get_node("GameSettings/VBoxContainer/TimerSettings/FocusSettings")
		Enums.PHASES.SHORT_PAUSE: return get_node("GameSettings/VBoxContainer/TimerSettings/ShortPauseSettings")
		Enums.PHASES.LONG_PAUSE: return get_node("GameSettings/VBoxContainer/TimerSettings/LongPauseSettings")

# Return the UI action button element as specified.
func get_action_button(type: Enums.ACTIONS):
	match type:
		Enums.ACTIONS.SOW: return get_node("ActionSelect/VBoxContainer/Sow")
		Enums.ACTIONS.WATER: return get_node("ActionSelect/VBoxContainer/Water")
		Enums.ACTIONS.HARVEST: return get_node("ActionSelect/VBoxContainer/Harvest")
		Enums.ACTIONS.NONE: return null

# To be called when a new phase starts by the game screen. Updates the UI according to the phase that the game is now newly in.
# Also sets itself to "track" the appropriate timer (for the timer display).
func handle_phase_change(phase: Enums.PHASES, timer: PhaseTimer) -> void:
	# Adjust UI Elements
	pause_button.disabled = false
	move_on_button.disabled = true
	move_on_button.visible = false
	match phase:
		Enums.PHASES.FOCUS: 
			# Disable shop.
			seed_shop.visible = false
			# Disable the action buttons so that no actions can be performed in the focus phase.
			for button in action_button_group.get_buttons():
				button.disabled = true
				button.button_pressed = false
			
			phase_label.text = "Focus"
			remaining_focuses_label.text = str(11 - ((game_screen.focus_counter) % 12)) + " Focus Phase(s)" 
		Enums.PHASES.SHORT_PAUSE: 
			# Enable the action buttons.
			for button in action_button_group.get_buttons():
				button.disabled = false
			# Enable shop.
			seed_shop.visible = true
			phase_label.text = "Break"

		Enums.PHASES.LONG_PAUSE: 
			# Enable the action buttons.
			for button in action_button_group.get_buttons():
				button.disabled = false
			# Enable shop.
			seed_shop.visible = true
			phase_label.text = "Long Break"
	
	tracked_timer = timer

# Called when game screen switches seasons. Update the UI accordingly.
func handle_season_change() -> void:
	match game_screen.current_season:
		Enums.SEASONS.BREEZY: season_label.text = "BREEZY"
		Enums.SEASONS.WARM: season_label.text = "WARM"
		Enums.SEASONS.RAINY: season_label.text = "RAINY"

# Returns the enum value of the action corresponding to the 
# button which is currently pressed in the UI action selection.
# Returns NONE if no button is clicked or found.
func get_current_action() -> Enums.ACTIONS:
	var button = action_button_group.get_pressed_button()
	if button:
		match button.name:
			"Sow": return Enums.ACTIONS.SOW
			"Water": return Enums.ACTIONS.WATER
			"Harvest": return Enums.ACTIONS.HARVEST
	return Enums.ACTIONS.NONE

# Returns the berry id of the currently selected seed
# in the seed inventory. Returns -1 if no button is clicked or found.
func get_selected_seed() -> int:
	var button = select_seed_button_group.get_pressed_button()
	if button:
		match button.name:
			"0": return 0
			"1": return 1
			"2": return 2
	return -1

# Runs every frame to update the timer minutes:seconds display, the owned berries display
# and the displayed amounts of owned seeds.
func _process(_delta) -> void:
	# Timer display.
	if tracked_timer:
		time_label.text = "%02d:%02d" % [tracked_timer.cur_minutes, tracked_timer.cur_seconds]
	# Owned berries amount.
	owned_berries_label.text = "Berries: %02d" % owned_berries
	# Seed Inventory, owned seed amounts.
	for i in range(3):
		seed_slots[i].get_amount_label().text = "%01d" % owned_seeds[i]
	

# Private.
# Called when the pause timer button is clicked.
# Changes the text of the pause timer so it accurately describes what happens
# on the next click.
func _on_pause_timer_toggled(_toggled_on: bool) -> void:
	match pause_button.text:
		"PAUSE TIMER":
			pause_button.text = "UNPAUSE TIMER"
		"UNPAUSE TIMER":
			pause_button.text = "PAUSE TIMER"

# Private.
# Called when the current phase's timer reaches 0. Makes appropriate UI and audio changes.
func _on_phase_over(_phase: Enums.PHASES) -> void:
	# Play alert sound
	audio.play_audio("AlertSound")
	# Adjust Phase Move-On Button
	move_on_button.disabled = false
	move_on_button.visible = true
	# Adjust Pause Button
	pause_button.disabled = true

# Private.
# Called when the save game button in the UI is pressed.
func _on_save_game_pressed() -> void:
	game_screen.save_game()
