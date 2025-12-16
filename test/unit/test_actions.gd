extends GutTest

var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var tile_set_manager : TileSetManager
var UI : CanvasLayer
var action_buttons
var pom_start_pos
var dest_tile : Tile

func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	tile_set_manager = game_screen.tile_set_manager
	# this has to be done because it looks for an absolute path including 
	# the screen manager for this reference. this node tree doesn't exist here though
	tile_set_manager.game_screen = game_screen 
	tile_set_manager.initialize_grid([])
	UI = game_screen.UI
	action_buttons = [UI.get_action_button(Enums.ACTIONS.SOW), UI.get_action_button(Enums.ACTIONS.WATER), UI.get_action_button(Enums.ACTIONS.HARVEST)]

func after_each():
	game_screen.free()
	

func test_sowing():
	
	#    0  1  2  3 
	# 0 [m][ ][ ][ ]        [m] = pom
	# 1 [ ][f][f][ ]        [f] = field
	# 2 [ ][ ][ ][ ]        [ ] = green
	
	tile_set_manager.get_tile(Vector2i(1,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(2,1)).set_state(Enums.TILE_STATES.DRY_FIELD)

	# Select the action as a player would.
	action_buttons[0].button_pressed = true
	action_buttons[1].button_pressed = false
	action_buttons[2].button_pressed = false
	
	var seed_slot_buttons : Array[Button]
	seed_slot_buttons.append(UI.seed_slots[0].get_select_button())
	seed_slot_buttons.append(UI.seed_slots[1].get_select_button())
	seed_slot_buttons.append(UI.seed_slots[2].get_select_button())
	game_screen.owned_seed_amount = [3,0,0] 
	
	## TEST 1: NOT A FIELD TILE
	seed_slot_buttons[0].button_pressed = true # select seed 0
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(2,2)) # green
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	assert_eq(dest_tile.get_state(), Enums.TILE_STATES.GREEN, "Tile should not have changed state (still be green).")
	
	## TEST 2: NO SEEDS AVAILABLE
	seed_slot_buttons[0].button_pressed = false # unselect seed 0 (!)
	seed_slot_buttons[1].button_pressed = true # select seed 1
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(2,1)) # field
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	assert_eq(dest_tile.plant_on_tile, null, "Nothing should be planted on destination tile.")
	
	## TEST 3: SUCCESS
	seed_slot_buttons[0].button_pressed = true # select seed 0
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,1)) # field
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_ne(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should have moved.")
	assert_ne(dest_tile.plant_on_tile, null, "A Plant should be on destination tile.")


func test_watering():
	
	#    0  1  2
	# 0 [m][ ][ ]       [m] = pom
	# 1 [ ][p][wp]      [p] = plant (on field), [wp] = watered plant
	# 2 [ ][w][ ]       [f] = field, [w] = wilted plant
	# 3 [ ][f][ ]       [ ] = green
	
	tile_set_manager.get_tile(Vector2i(1,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(1,2)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(2,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(1,3)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	tile_set_manager.spawn_plant_on_tile(Vector2i(1,1), 0)
	tile_set_manager.spawn_plant_on_tile(Vector2i(1,2), 0).wilt()
	tile_set_manager.spawn_plant_on_tile(Vector2i(2,1), 0)
	tile_set_manager.get_tile(Vector2i(2,1)).water_tile()
	
	# Select the action as a player would.
	action_buttons[0].button_pressed = false
	action_buttons[1].button_pressed = true
	action_buttons[2].button_pressed = false
	
	## TEST 1: NO PLANT
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,3)) # dry field
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	assert_eq(dest_tile.get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile should not have changed state (still be dry field).")
	
	## TEST 2: PLANT WILTED
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,2)) # wilted
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	assert_eq(dest_tile.get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile should not have changed state (still be dry field).")
	assert_eq(dest_tile.plant_on_tile.watered, false, "Plant should not count as watered.")
	
	## TEST 3: SUCCESS
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,1)) # plant
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_ne(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should have moved.")
	assert_eq(dest_tile.get_state(), Enums.TILE_STATES.WATERED_FIELD, "Field should have changed state to watered.")
	assert_eq(dest_tile.plant_on_tile.watered, true, "Plant should count as watered.")
	
	## TEST 4: ALREADY WATERED
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(2,1)) # watered plant 
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")


func test_harvesting():
	
	#    0  1  2
	# 0 [m][ ][ ]       [m] = pom
	# 1 [ ][p][f]       [p] = plant (on field)
	# 2 [ ][w][ ]       [w] = wilted plant
	# 3 [ ][p][ ]       [ ] = green
	
	tile_set_manager.get_tile(Vector2i(1,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(1,2)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(1,3)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(2,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	tile_set_manager.spawn_plant_on_tile(Vector2i(1,1), 0)
	tile_set_manager.spawn_plant_on_tile(Vector2i(1,2), 0).wilt()
	var plant_fully_grown = tile_set_manager.spawn_plant_on_tile(Vector2i(1,3), 0)
	plant_fully_grown.max_growth_stage = 1
	tile_set_manager.get_tile(Vector2i(1,3)).water_tile()
	plant_fully_grown.grow()
	
	# Select the action as a player would.
	action_buttons[0].button_pressed = false
	action_buttons[1].button_pressed = false
	action_buttons[2].button_pressed = true
	
	## TEST 1: NO PLANT
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(2,1)) # dry field
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	
	## TEST 2: PLANT WILTED
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,2)) # wilted
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_ne(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should have moved.")
	assert_eq(dest_tile.plant_on_tile, null, "Plant should be gone.")
	
	## TEST 3: PLANT NOT GROWN
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,1)) # watered plant 
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_eq(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should not have moved.")
	assert_ne(dest_tile.plant_on_tile, null, "Plant should not be gone.")
	
	## TEST 4: SUCCESS
	pom_start_pos = tile_set_manager.pom.on_tile.grid_pos
	dest_tile = tile_set_manager.get_tile(Vector2i(1,3)) # plant
	
	game_screen.commit_action(dest_tile)
	await wait_for_signal(tile_set_manager.movement_complete, 2.0)
	assert_ne(pom_start_pos, tile_set_manager.pom.on_tile.grid_pos, "Pom should have moved.")
	assert_eq(dest_tile.plant_on_tile, null, "Plant should be gone.")
	
