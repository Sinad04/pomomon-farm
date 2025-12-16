extends GutTest

var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var save_state_scene = preload("res://scenes/save_state.tscn")
var tile_set_manager: TileSetManager

var save_file : FileAccess
var save_dictionary : Dictionary
var save_state : SaveState

func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	tile_set_manager = game_screen.tile_set_manager
	tile_set_manager.grid_size = Vector2i(5,5)
	
	save_state = save_state_scene.instantiate()

func after_each():
	for id in range(3):
		DirAccess.remove_absolute("user://save-state-%01d.json" % id)
	save_state.free()
	game_screen.free()


func test_valid_save_loading():
	## TEST 1
	# Test whether the save state object can load the example save state below correctly.
	save_state.save_state_id = 1
	save_dictionary = {
		"farmState": {"unlockedTiles": 
			[ { "x": 1, "y": 1, "plantedBerryId": 0, "growthStage": 2, "watered": false, "withered": false },
			{ "x": 1, "y": 2, "plantedBerryId": null, "growthStage": 1, "watered": true, "withered": false }, 
			{ "x": 4, "y": 4, "plantedBerryId": 1, "growthStage": 1, "watered": false, "withered": true }, 
			{ "x": 2, "y": 2, } ], # no information beside x and y
			"cols": 5, "rows": 5
			},
		"inventory": { "berrySeeds": { "0": 1, "1": 4, "2": 88 }, "totalBerries": 1234 },
		"timers": 
		{ "focusMinutes": 4, "focusSeconds": 33,
			"breakMinutes": 17, "breakSeconds": 1,
			"longBreakMinutes": 8, "longBreakSeconds": 0 }, 
		"session": { "focusPhasesCompleted": 5, "currentActivePhase": "FOCUS" }}
	
	# Write a valid save file.
	save_file = FileAccess.open("user://save-state-1.json", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(save_dictionary))
	save_file.close()
	
	# Make the save object read from it's corresponding json file.
	save_state.read_state_from_json()
	
	game_screen.no_auto_load = false
	game_screen.load_game(save_state)
	
	assert_eq(game_screen.owned_berry_amount, 1234, "Owned berries should be as they are in save file.")
	assert_eq(game_screen.owned_seed_amount, [1,4,88], "Owned seeds should be as they are in save file.")
	
	assert_eq(game_screen.focus_timer.get_settings(), Vector2i(4,33), "Focus Timer settings should be as they are in save file.")
	assert_eq(game_screen.short_pause_timer.get_settings(), Vector2i(17,1), "Short Pause Timer settings should be as they are in save file.")
	assert_eq(game_screen.long_pause_timer.get_settings(), Vector2i(8,0), "Long Pause Timer settings should be as they are in save file.")
	
	assert_eq(game_screen.focus_counter, 5, "Focus counter should be as it is in save file.")
	assert_eq(game_screen.current_phase, Enums.PHASES.FOCUS, "Current phase should be as it is in save file.")
	
	for x in range(4):
		for y in range(4):
			match Vector2i(x,y):
				Vector2i(1,1), Vector2i(2,2), Vector2i(4,4):
					assert_eq(tile_set_manager.get_tile(Vector2i(x,y)).get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile %s,%s should be unlocked." % [x,y])
				Vector2i(1,2):
					assert_eq(tile_set_manager.get_tile(Vector2i(x,y)).get_state(), Enums.TILE_STATES.WATERED_FIELD, "Tile %s,%s should be unlocked and watered." % [x,y])
				_:
					assert_eq(tile_set_manager.get_tile(Vector2i(x,y)).get_state(), Enums.TILE_STATES.GREEN, "Tile %s,%s should not be unlocked." % [x,y])
	
	assert_ne(tile_set_manager.get_tile(Vector2i(1,1)).plant_on_tile, null, "Tile %s,%s should have a plant." % [1,1])
	assert_eq(tile_set_manager.get_tile(Vector2i(1,1)).plant_on_tile.cur_growth_stage, 2, "Tile %s,%s plant should have growth stage 2." % [1,1])
	assert_ne(tile_set_manager.get_tile(Vector2i(4,4)).plant_on_tile, null, "Tile %s,%s should be unlocked." % [4,4])
	assert_eq(tile_set_manager.get_tile(Vector2i(4,4)).plant_on_tile.wilted, true, "Tile %s,%s plant should be wilted." % [4,4])

func test_save_reset():
	## TEST 1
	# Test whether the reset save function sets the boolean correctly and whether the default is correctly applied during it.
	save_state.reset_save_state()
	
	assert_eq(save_state.empty, true, "Save State should count as empty.")
	
	# Re-enable the game doing save loading.
	game_screen.no_auto_load = false
	
	# Simulate choosing the grid size "Large" (9*5 field tiles) here.
	save_state.grid_size = Vector2i(11,7)
	
	game_screen.load_game(save_state)
	
	assert_eq(game_screen.owned_berry_amount, 5, "Owned berries should be default.")
	assert_eq(game_screen.owned_seed_amount, [1,0,0], "Owned seeds should be default.")
	
	assert_eq(game_screen.focus_timer.get_settings(), Vector2i(25,0), "Focus Timer settings should be default.")
	assert_eq(game_screen.short_pause_timer.get_settings(), Vector2i(5,0), "Short Pause Timer settings should be default.")
	assert_eq(game_screen.long_pause_timer.get_settings(), Vector2i(15,0), "Long Pause Timer settings should be default.")
	
	assert_eq(game_screen.focus_counter, 0, "Focus counter should be default.")
	assert_eq(game_screen.current_phase, Enums.PHASES.SHORT_PAUSE, "Current phase should default.")
	
	for x in range(4):
		for y in range(4):
			match Vector2i(x,y):
				Vector2i(1,1):
					assert_eq(tile_set_manager.get_tile(Vector2i(x,y)).get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile %s,%s should be unlocked." % [x,y])
				_:
					assert_eq(tile_set_manager.get_tile(Vector2i(x,y)).get_state(), Enums.TILE_STATES.GREEN, "Tile %s,%s should not be unlocked." % [x,y])
