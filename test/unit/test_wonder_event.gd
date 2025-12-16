extends GutTest

var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var tile_set_manager : TileSetManager
var wonder_event_handler



func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	tile_set_manager = game_screen.tile_set_manager
	tile_set_manager.game_screen = game_screen # the field will be null otherwise since it uses an absolute path
	wonder_event_handler = tile_set_manager.wonder_event_handler
	wonder_event_handler.enabled = false # we don't want any uncontrolled behavior in this test
	tile_set_manager.grid_size = Vector2i(10,10)
	# Everything will be green when this grid is initialized.
	tile_set_manager.initialize_grid([])
	
func after_each():
	game_screen.free()


func test_wonder_event_execution():
	
	var growth_stages_before : Array
	
	# Place some field tiles and plants.
	for pos in [Vector2i(3,3), Vector2i(3,4), Vector2i(4,3), Vector2i(7,7)]:
		tile_set_manager.get_tile(pos).set_state(Enums.TILE_STATES.DRY_FIELD)
		# set favored seasons to empty regardless of config, to normalize growth behavior for test purposes
		(tile_set_manager.spawn_plant_on_tile(pos, 0)).favored_seasons = [] 
	
	
	tile_set_manager.get_tile(Vector2i(1,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	## TEST 1 PLANTS AND NEIGHBORS
	
	growth_stages_before = [tile_set_manager.get_tile(Vector2i(3,3)).plant_on_tile.cur_growth_stage,
	tile_set_manager.get_tile(Vector2i(3,4)).plant_on_tile.cur_growth_stage,
	tile_set_manager.get_tile(Vector2i(4,3)).plant_on_tile.cur_growth_stage,
	tile_set_manager.get_tile(Vector2i(7,7)).plant_on_tile.cur_growth_stage]
	
	tile_set_manager._wonder_event(Vector2i(3,3)) # Simulate wonder event occurring.
	
	assert_eq(tile_set_manager.get_tile(Vector2i(3,3)).plant_on_tile.cur_growth_stage, growth_stages_before[0]+1, "Plant on (3,3) should have grown.")
	assert_eq(tile_set_manager.get_tile(Vector2i(3,4)).plant_on_tile.cur_growth_stage, growth_stages_before[1]+1, "Plant on (3,4) should have grown.")
	assert_eq(tile_set_manager.get_tile(Vector2i(4,3)).plant_on_tile.cur_growth_stage, growth_stages_before[2]+1, "Plant on (4,3) should have grown.")
	assert_eq(tile_set_manager.get_tile(Vector2i(7,7)).plant_on_tile.cur_growth_stage, growth_stages_before[3], "Plant on (7,7) should not have grown.")
	
	## TEST 2 EMPTY FIELD
	
	tile_set_manager._wonder_event(Vector2i(1,1)) # Empty field.
	
	assert_eq(tile_set_manager.get_tile(Vector2i(1,1)).get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile (1,1) should not have changed.")

func test_wonder_event_requests_and_responses():
	
	var request
	var response
	watch_signals(wonder_event_handler)
	
	
	## TEST 1 BUILD REQUEST
	wonder_event_handler.grid_size = Vector2i(6,8)
	request = wonder_event_handler._build_request()
	assert_eq_deep(request, {"messageType": "WONDER_REQUEST", "maxFieldSize": {"minX": 1, "maxX": 4,"minY": 1, "maxY": 6}})
	
	## TEST 2 CHECK RESPONSE NOT GRANTED
	response = {"messageType": "NO_WONDER"}
	wonder_event_handler.check_response(response)
	assert_signal_not_emitted(wonder_event_handler.wonder_event, "Wonder event should not have been emitted after response NO_WONDER")
	
	## TEST 3 CHECK RESPONSE GRANTED
	response = {"messageType": "WONDER_GRANTED", "position": {"x": 3, "y": 4}}
	wonder_event_handler.check_response(response)
	assert_signal_emitted_with_parameters(wonder_event_handler.wonder_event, [Vector2i(3,4)])
