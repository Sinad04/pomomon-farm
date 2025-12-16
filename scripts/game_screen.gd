extends Node2D

var current_season : Enums.SEASONS = Enums.SEASONS.BREEZY
var current_phase : Enums.PHASES = Enums.PHASES.SHORT_PAUSE
# This counts how many short pause phases have been completed in this SESSION.
var short_pauses_counter : int = 0
# This counts how many focus phases have been completed in this SAVE.
var focus_counter : int = 0
# This counts how many berries the player currently owns.
var owned_berry_amount : int = 5
# This counts how many seeds the player owns in an array, where berry id corresponds to array index.
# By default the player gets one seed of the berry id 0 and nothing else.
var owned_seed_amount : Array = [1,0,0]
# To counter spam-clicking breaking actions.
var moving : bool = false
# Set to true if game screen scene should NOT load any save state even if invoked to.
@export var no_auto_load : bool = false
# Whether purchase mode is active right now.
var purchase_mode : bool = false
# Array of purchasable tiles. Filled during purchase mode and emptied afterwards. Used to clear "purchaseable" markers.
var pur_markers : Array = []
# Various game objects this node handles or interacts with.
@onready var current_save_state : SaveState
@onready var dummy_plant = get_node("DummyPlant")
@onready var focus_timer = get_node("FocusTimer")
@onready var short_pause_timer = get_node( "ShortPauseTimer")
@onready var long_pause_timer = get_node("LongPauseTimer")
@onready var current_timer : PhaseTimer
@onready var UI = get_node("UI")
@onready var tile_set_manager = get_node("TileSetManager")

func _ready() -> void:
	load_game(current_save_state)

# When called this method checks which season the game is currently in.
# All plants will be wilted, and then a new season will be started according to the
# order Breezy, Warm, Rainy, repeat..
func switch_season() -> void:
	tile_set_manager.wilt_all_plants()
	current_season = (current_season + 1) % 3 as Enums.SEASONS
	UI.handle_season_change()

# When called this method checks which phase the game is currently in.
# Depending on this it will manipulate the amount of completed short pauses, and then call
# the _start_phase method with the phase that would come next.
func switch_phase() -> void:
	match current_phase:
		Enums.PHASES.FOCUS:
			focus_counter += 1
			# Handle berry reward.
			owned_berry_amount += current_timer.minutes_at_start*2
			# If 3 short pauses have been completed since the last long one 
			# (or since the beginning of the session),
			# a long one is started instead of a short one.
			if short_pauses_counter == 3:
				short_pauses_counter = 0
				_start_phase(Enums.PHASES.LONG_PAUSE)
			else:
				_start_phase(Enums.PHASES.SHORT_PAUSE)
		Enums.PHASES.SHORT_PAUSE:
			short_pauses_counter += 1
			_start_phase(Enums.PHASES.FOCUS)
		Enums.PHASES.LONG_PAUSE:
			_start_phase(Enums.PHASES.FOCUS)
		_:
			_start_phase(Enums.PHASES.FOCUS)

# Private.
# Sets the current phase field accordingly and starts the timer of the given phase.
# In the case of a new focus phase starting it also checks and handles a potential season switch.
func _start_phase(new_phase: Enums.PHASES) -> void:
	current_phase = new_phase
	match new_phase:
		Enums.PHASES.FOCUS:
			current_timer = focus_timer
			if (focus_counter % 12 == 0 && focus_counter > 0):
				switch_season()
		Enums.PHASES.SHORT_PAUSE:
			current_timer = short_pause_timer
		Enums.PHASES.LONG_PAUSE:
			current_timer = long_pause_timer
	UI.handle_phase_change(new_phase, current_timer)
	current_timer.start_timer()

# Toggles pause on the timer when the pause button is pressed.
func _on_pause_timer_button_toggled(_toggled_on: bool) -> void:
	current_timer.toggle_pause_timer()

# Switches to next phase when the move on button is pressed.
func _on_move_on_button_pressed() -> void:
	switch_phase()

# Perform transaction for purchasing a seed.
# Called when a corresponding seed listing emits a signal.
func purchase_seed(id: int, price: int) -> void:
	if (owned_berry_amount >= price):
		owned_berry_amount -= price
		owned_seed_amount[id] += 1

# Perform transaction for purchasing a new tile and enter purchase mode.
# Called when a corresponding tile listing emits a signal.
func purchase_tile(price: int) -> void:
	if (owned_berry_amount >= price):
		owned_berry_amount -= price
		UI.tile_listing.cur_price *= Configuration.tile_cost_increase
		UI.tile_listing.update_display()
		_toggle_purchase_mode()

# Toggles purchase mode, by making the necessary changes to UI elements and marking all purchasable tiles.
func _toggle_purchase_mode() -> void:
	if purchase_mode:
		purchase_mode = false
		tile_set_manager.pom.visible = true
		UI.visible = true
		
		# If in the purchase mode that just ended, there was only one marker being used,
		# that means that was the last possible purchase of a tile - all of them are unlocked now.
		# To prevent softlocking yourself in the purchase mode from this point on, the buy button is disabled.
		# Note that upon loading a save state, it is checked seperately from this 
		# whether the buy button should be clickable.
		if pur_markers.size() <= 1: # equal OR less than because you never know
			UI.tile_listing.get_buy_button().disabled = true
		
		for marker in pur_markers:
			marker.queue_free()
		pur_markers.clear()
	else:
		purchase_mode = true
		tile_set_manager.pom.visible = false
		UI.visible = false
		UI.get_action_button(Enums.ACTIONS.SOW).button_pressed = false
		UI.get_action_button(Enums.ACTIONS.WATER).button_pressed = false
		UI.get_action_button(Enums.ACTIONS.HARVEST).button_pressed = false
		pur_markers = tile_set_manager.mark_purchaseable_tiles()
		for marker in pur_markers:
			# When one of the markers is clicked, purchase mode ends. The actual conversion to 
			# field is done by the marker object on top of the tile.
			marker.purchased.connect(_toggle_purchase_mode)

# This function takes a tile. It checks which action is currently selected in the UI,
# It then calls to find a path to the tile. If one is found it waits for the movement to be completed and
# calls the corresponding function to execute that action on that tile.
# This function is linked to the signal mouse_clicked_on_tile of every tile instance by the tile set manager.
func commit_action(tile: Tile) -> void:
	if moving: return # ignore click if an action is being done already right now
	moving = true
	var button = UI.action_button_group.get_pressed_button() # do this here to prevent switching up during movement
	var selected_seed = UI.get_selected_seed() # do this here to prevent switching up during movement
	var pom_tile = tile_set_manager.pom.on_tile
	var path_to_take = tile_set_manager.path_finder.find_shortest_path(pom_tile, tile)
	# If the path exists. (if no path is found the array is length 0. if one IS found it is at least length 1.
	# In particular, the path is of size one when the destination tile equals the start tile (clicked on the pom).
	if path_to_take.size() >= 1 : 
		if button:
			match button.name:
				"Sow": # Perform if and only if tile is free and is a field tile.
					if owned_seed_amount[selected_seed] > 0:
							if !tile.plant_on_tile && tile.state == Enums.TILE_STATES.DRY_FIELD:
								## Check for trapping ##
								tile.plant_on_tile = dummy_plant # Set the dummy plant (to simulate how the grid would be after this sow were to be performed).
								# Remove the final tile from the path, since it's the tile the action is to be performed on.
								path_to_take.resize(path_to_take.size()-1)
								# From where the "escape path" is to be determined. It is the the last tile of the shortened original path.
								var escape_path
								# Whether the Pomomon isn't already on the destination tile.
								# (if it is, we don't need to bother with finding a "first" escape path, since we'll be using the alternative one anyway).
								if  pom_tile != tile: 
									var escape_start = tile_set_manager.get_tile(path_to_take[-1]) 
									# Determine if there's an escape path from the tile the Pom would be on on the grid as it would be right after performing the action.
									escape_path = tile_set_manager.path_finder.find_shortest_path(escape_start, tile_set_manager.get_tile(Vector2i(0,0)))
								else: escape_path = []
								# IF either 
								# - we don't have an escape path from our prospective starting point OR 
								# - we're already on top of the destination, 
								# then we need to try an alternative (escape-) path from a neighboring tile instead.
								if escape_path.size() == 0: 
									for alt_tile in tile_set_manager.get_tile_neighbors(tile): 
										if !alt_tile.plant_on_tile: # Check if alt tile is walkable
											# Determine if there's an escape starting from any neighbors of the destination tile.
											escape_path = tile_set_manager.path_finder.find_shortest_path(alt_tile, tile_set_manager.get_tile(Vector2i(0,0)))
											if escape_path.size() > 0:
												tile.plant_on_tile = null # Remove the dummy plant.
												# Used if Pom is on top of the destination tile, to "dodge" away to an alt tile that we now know has an escape path.
												var dodge_path : Array[Vector2i] = [pom_tile.grid_pos, alt_tile.grid_pos]
												# Set path to end at the alt tile instead.
												path_to_take = tile_set_manager.path_finder.find_shortest_path(pom_tile, alt_tile) if pom_tile != tile else dodge_path
												break
								tile.plant_on_tile = null # Remove the dummy plant.
								if escape_path.size() > 0: # If we are able to escape.
									tile_set_manager.move_pom_on_path(path_to_take, 0)
									await tile_set_manager.movement_complete 
									owned_seed_amount[selected_seed] -= 1
									tile.sow_tile(selected_seed)
				"Water": # Perform if and only if tile has a plant that is NOT watered NOR wilted.
					if tile.plant_on_tile:
						if !tile.plant_on_tile.wilted && !tile.plant_on_tile.fully_grown && !tile.plant_on_tile.watered:
							path_to_take.resize(path_to_take.size()-1) # Remove the final tile from the path, since it's the tile the action is to be performed on.
							tile_set_manager.move_pom_on_path(path_to_take, 0)
							await tile_set_manager.movement_complete 
							tile.water_tile()
				"Harvest": # Perform if and only if tile has a plant that is fully grown OR wilted.
						if tile.plant_on_tile:
							if tile.plant_on_tile.fully_grown || tile.plant_on_tile.wilted:
								path_to_take.resize(path_to_take.size()-1) # Remove the final tile from the path, since it's the tile the action is to be performed on.
								tile_set_manager.move_pom_on_path(path_to_take, 0)
								await tile_set_manager.movement_complete 
								owned_berry_amount += tile.harvest_tile()
	moving = false

# Returns the Phase Timer object that is the child of this game screen, according to specified phase type.
func get_timer(type: Enums.PHASES) -> PhaseTimer:
	match type:
		Enums.PHASES.FOCUS: return get_node("FocusTimer")
		Enums.PHASES.SHORT_PAUSE: return get_node("ShortPauseTimer")
		Enums.PHASES.LONG_PAUSE: return get_node("LongPauseCounter")
		_: return null

# Change the timer settings according to given argument.
# This listens to signals from the timer settings UI.
func _change_timer_settings(type: Enums.PHASES, settings: Vector2i) -> void:
	match type:
		Enums.PHASES.FOCUS: focus_timer.set_timer(settings.x, settings.y)
		Enums.PHASES.SHORT_PAUSE: short_pause_timer.set_timer(settings.x, settings.y)
		Enums.PHASES.LONG_PAUSE: long_pause_timer.set_timer(settings.x, settings.y)

# Set the passed argument as the current save state and apply all the fields into the environment.
# This is called by the screen manager, but can be stopped from running 
# by setting the no_auto_load field in this script accordingly (top).
func load_game(save_state: SaveState) -> void:
	if no_auto_load: return
	
	###############
	## Internals ##
	###############
	
	current_save_state = save_state
	
	owned_berry_amount = current_save_state.total_berries
	owned_seed_amount = current_save_state.seed_inventory
	
	focus_counter = current_save_state.focus_phases_completed
	current_phase = current_save_state.current_phase
	
	# Set the timers according to saved settings.
	var tset = current_save_state.timer_settings
	focus_timer.set_timer(tset[0].x, tset[0].y)
	short_pause_timer.set_timer(tset[1].x, tset[1].y)
	long_pause_timer.set_timer(tset[2].x, tset[2].y)
	
	# Set the shop's tile price according to how many unlocked field tiles there already are.
	for i in range(save_state.unlocked_tiles.size()):
		if i>0: UI.tile_listing.cur_price *= Configuration.tile_cost_increase
	
	# Begin the phase the game was saved in. If it was saved in a pause phase the timer is skipped.
	match current_phase:
		Enums.PHASES.FOCUS: _start_phase(Enums.PHASES.FOCUS)
		Enums.PHASES.SHORT_PAUSE: 
			_start_phase(Enums.PHASES.SHORT_PAUSE)
			current_timer.skip_timer()
		Enums.PHASES.LONG_PAUSE: 
			_start_phase(Enums.PHASES.LONG_PAUSE)
			current_timer.skip_timer()
	
	# Reconstruct what season we're in and establish it.
	var focuses_completed = focus_counter
	while focuses_completed > 12:
		focuses_completed -= 12
		switch_season() # This does not spam-wilt the player's plants since the grid isn't generated yet.
	
	##########
	## GRID ##
	##########
	
	# Set grid size according to saved state.
	tile_set_manager.grid_size = current_save_state.grid_size
	
	# Initialize the grid, passing which tiles should be unlocked and what they contain.
	tile_set_manager.initialize_grid(save_state.unlocked_tiles)
	
	########
	## UI ##
	########
	
	# Set and update the timer settings UI to be accurate to the actual current internal settings.
	var timer_uis = [UI.get_timer_settings(Enums.PHASES.FOCUS), UI.get_timer_settings(Enums.PHASES.SHORT_PAUSE), UI.get_timer_settings(Enums.PHASES.LONG_PAUSE)]
	for i in range(3):
		timer_uis[i].minutes_setting = tset[i].x
		timer_uis[i].seconds_setting = tset[i].y
		timer_uis[i].update_ui(0)
		timer_uis[i].update_ui(1)
		timer_uis[i].update_ui(2)
		timer_uis[i].update_ui(3)
	UI.tile_listing.update_display()
	
	# doing the UIs job this one time so it loads displaying correctly how many focus phases remain until season switch.
	if ((focus_counter) % 12)!= 0 || focus_counter == 0:
		UI.remaining_focuses_label.text = str(11 - ((focus_counter) % 12)) + " Focus Phase(s)" 
		# this is the special case that causes problems when loading into a pause phase when the focus phases are all 
		# through: the actual season switch after the pause phase hasn't happened yet. So the display would be lying.
		# (because the way I coded it, it expects to only be updated at the start of focus phases. 
		# This is only a problem that can occur when loading from a save.
	else: UI.remaining_focuses_label.text = "After the break!" 
	UI.handle_season_change() # Update the display of what season it is.
	
	# If all tiles are unlocked, then disable the buy button to prevent becoming trapped forever in the purchase mode.
	if save_state.unlocked_tiles.size() >= (tile_set_manager.grid_size.x-2) * (tile_set_manager.grid_size.y-2):
		UI.tile_listing.get_buy_button().disabled = true


# Write all the environment fields into the current save state's fields.
func save_game() -> void:
	
	current_save_state.unlocked_tiles.clear() # Needed because I'm using append
	
	##########
	## Grid ##
	##########
	
	# Save all unlocked tiles.
	for x in range(tile_set_manager.grid_size.x):
		for y in range(tile_set_manager.grid_size.y):
			var tile_save : Dictionary = {}
			var tile = tile_set_manager.get_tile(Vector2i(x,y))
			if tile.get_state() != Enums.TILE_STATES.GREEN:
				tile_save.get_or_add("pos", Vector2i(tile.grid_pos.x, tile.grid_pos.y))
				if tile.plant_on_tile:
					tile_save.get_or_add("plantedBerryId", tile.plant_on_tile.berry_id)
					tile_save.get_or_add("growthStage", tile.plant_on_tile.cur_growth_stage)
					tile_save.get_or_add("watered", tile.get_state() == Enums.TILE_STATES.WATERED_FIELD)
					tile_save.get_or_add("withered", tile.plant_on_tile.wilted)
				else: 
					tile_save.get_or_add("plantedBerryId", null)
					tile_save.get_or_add("growthStage", 0)
					tile_save.get_or_add("watered", false)
					tile_save.get_or_add("withered", false)
				current_save_state.unlocked_tiles.append(tile_save)
	###############
	## Internals ##
	###############
	current_save_state.total_berries = owned_berry_amount
	current_save_state.seed_inventory = owned_seed_amount
	current_save_state.timer_settings = [focus_timer.get_settings(), short_pause_timer.get_settings(), long_pause_timer.get_settings()]
	current_save_state.focus_phases_completed = focus_counter
	current_save_state.current_phase = current_phase
	current_save_state.empty = false # Saving makes a state not "empty" anymore. (Only relevant on the very first save)
	current_save_state.write_state_to_json() # Write-through.
