class_name ScreenManager extends Node

var current_screen
@onready var config_loader = get_node("ConfigLoader")

# This node is the root of the node tree of the entire game. It has the current screen as it's child as well as some other
# important nodes which handle internal game data, namely config and save states, plus an audio manager.
# It's main purpose is to handle the "switch" between screens by killing and creating the appropriate nodes.

# Application Startup. Read config and load into the start screen.
func _ready() -> void:
	config_loader.read_config_file()
	switch_to_start_screen()

##############################
######  MANAGE SCREENS  ######
############################## 

# Makes the screen manager switch to the game screen, using the provided save state.
# The grid size argument is only relevant on a save state that is loaded for the first time (starting a new empty one) to set that
# value properly in that save state
func switch_to_game_screen(save_state: SaveState, grid_size: Vector2i) -> void:
	var game_screen = preload("res://scenes/game_screen.tscn").instantiate()
	# Tie the game screen's exit button to call the function that switches to start screen upon being pressed.
	var exit_button = game_screen.get_node("UI/GameSettings/VBoxContainer/StateSettings/ExitGame")
	# If the grid_size argument to this function is the zero vector, it means the grid_size is already in the save state and must not be newly set.
	if grid_size: save_state.grid_size = grid_size
	game_screen.current_save_state = save_state
	exit_button.pressed.connect(switch_to_start_screen)
	switch_screen(game_screen)

# Makes the screen manager switch to the start screen.
func switch_to_start_screen() -> void:
	var start_screen = preload("res://scenes/start_screen.tscn").instantiate()
	# Connect the load button of each save state listing to the function that switches to the game_screen.
	start_screen.load_save_state.connect(switch_to_game_screen)
	switch_screen(start_screen)

# Takes an instantiated(!) scene as an argument and makes it the new current screen, deleting the old one.
func switch_screen(new_screen) -> void:
	if current_screen:
		current_screen.queue_free()
	current_screen = new_screen
	add_child(new_screen)
	
