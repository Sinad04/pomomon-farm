extends GutTest

var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var tile_set_manager : TileSetManager

func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	tile_set_manager = game_screen.tile_set_manager
	tile_set_manager.grid_size = Vector2i(10,10)
	# Everything will be green when this grid is initialized.
	tile_set_manager.initialize_grid([])
	
func after_each():
	game_screen.free()


func test_tile_marking():
	var tiles_to_be_marked = [Vector2i(1,2), Vector2i(2,1), # regarding field (1,1), importantly (0,1) and (1,0) are excluded: edge tiles
	Vector2i(5,4), Vector2i(4,5), Vector2i(4,3), # regarding field (4,4), importantly (3,4) is excluded: already field
	Vector2i(2,3), Vector2i(3,2),  # regarding field (3,3), importantly (3,4) is excluded: already field; (4,3) already included in line above
	Vector2i(3,5), Vector2i(2,4)] # regarding field (3,4), importantly (3,3) and (4,4) are excluded: already field
	
	tile_set_manager.get_tile(Vector2i(4,4)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(3,4)).set_state(Enums.TILE_STATES.DRY_FIELD)
	tile_set_manager.get_tile(Vector2i(3,3)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	# Tile right next to edge tiles (which are not ever to be marked).
	# An edge case if you will
	tile_set_manager.get_tile(Vector2i(1,1)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	var markers = tile_set_manager.mark_purchaseable_tiles()
	
	# For each marker check if it's marking a tile that is supposed to be marked.
	for marker in markers:
		var pos = marker.tile.grid_pos
		var marked = tiles_to_be_marked.has(pos)
		assert_eq(marked, true, "Tile %s should be marked." % pos)
		if marked: tiles_to_be_marked.erase(pos)
	
	# If this array is empty and no asserts prior to this have failed, that means all correct tiles and only those have been marked.
	assert_eq(tiles_to_be_marked.is_empty(), true, "All correct tiles should be marked.")



func test_tile_conversion():
	# Single field tile.
	tile_set_manager.get_tile(Vector2i(2,2)).set_state(Enums.TILE_STATES.DRY_FIELD)
	
	var tile_to_buy
	
	## TEST 1 CLICK PURCHASEABLE TILE
	# Simulate wanting to buy.
	game_screen._toggle_purchase_mode()
	assert_eq(game_screen.purchase_mode, true, "Purchase mode should be toggled to true.")
	
	tile_to_buy = tile_set_manager.get_tile(Vector2i(1,2))
	tile_to_buy.mouse_clicked_on_tile.emit() # Simulate click.
	
	assert_eq(tile_to_buy.get_state(), Enums.TILE_STATES.DRY_FIELD, "Tile (1,2) should be field after clicked.")
	assert_eq(game_screen.purchase_mode, false, "Purchase mode should be toggled back to false.")
	
	## TEST 2 CLICK FIELD TILE
	# Simulate wanting to buy.
	game_screen._toggle_purchase_mode()
	assert_eq(game_screen.purchase_mode, true, "Purchase mode should be toggled to true.")
	
	tile_to_buy = tile_set_manager.get_tile(Vector2i(2,2))
	tile_to_buy.mouse_clicked_on_tile.emit() # Simulate click.
	
	assert_eq(tile_to_buy.get_state(), Enums.TILE_STATES.DRY_FIELD, "Nothing should have happened to tile (2,2).")
	assert_eq(game_screen.purchase_mode, true, "Purchase mode should still be true.")
