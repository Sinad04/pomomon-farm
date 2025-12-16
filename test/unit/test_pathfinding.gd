extends GutTest

var tile_set_manager_scene = preload("res://scenes/tile_set_manager.tscn")
var plant_scene = preload("res://scenes/plant.tscn")

var path_finder : PathFinder
var start_tile : Tile
var dest_tile : Tile
var tile_set_manager : TileSetManager
var exp_len : int


func before_all():
	tile_set_manager = tile_set_manager_scene.instantiate()
	add_child(tile_set_manager)
	path_finder = tile_set_manager.path_finder
	tile_set_manager.initialize_grid([])

func after_all():
	tile_set_manager.free()


# Note that the find_shortest_path() function is intended to return the full path, *including* the start and end position.
# So if n "steps" (movements from one tile to an adjacent one) must be taken from 
# the start tile to the destination tile, the "length" of that path is n+1.

# Test the pathfinding in general, especially edge cases, without considering obstacles in the path.
func test_paths_without_obstacles():
	
	var result : Array[Vector2i]
	
	## TEST 1
	start_tile = tile_set_manager.get_tile(Vector2i(1,4))
	dest_tile = tile_set_manager.get_tile(Vector2i(3,3))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 4
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	## TEST 2
	start_tile = tile_set_manager.get_tile(Vector2i(0,1))
	dest_tile = tile_set_manager.get_tile(Vector2i(0,2))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 2
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	## TEST 3
	start_tile = tile_set_manager.get_tile(Vector2i(3,3))
	dest_tile = tile_set_manager.get_tile(Vector2i(3,3))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 1
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])


# Test the pathfinding on a grid with obstacles.

func test_paths_with_obstacles():
	
	var result : Array[Vector2i]
	var obstacles : Array[Plant]
	var obstacle : Plant
	
	## TEST 1
	#    0  1  2  3  4  ..
	# 0 [ ][ ][ ][x][ ]
	# 1 [ ][x][ ][ ][ ]
	# 2 [ ][x][ ][x][ ]
	# 3 [ ][ ][ ][x][ ]
	# 4 [ ][x][ ][ ][ ] 
	# ..
	
	# Place the obstacles (see above)
	for pos in [Vector2i(1,1), Vector2i(1,2) ,Vector2i(1,4), 
				Vector2i(3,0), Vector2i(3,2), Vector2i(3,3)]:
		obstacle = plant_scene.instantiate()
		obstacle.set_on_tile(tile_set_manager.get_tile(pos))
		add_child(obstacle)
	
	# TEST 1a
	start_tile = tile_set_manager.get_tile(Vector2i(0,2))
	dest_tile = tile_set_manager.get_tile(Vector2i(2,2))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 5
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	# TEST 1b
	start_tile = tile_set_manager.get_tile(Vector2i(0,0))
	dest_tile = tile_set_manager.get_tile(Vector2i(0,3)) # End on top of obstacle.
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 4
	
	# Should not hinder a path being found, since obstacles are also the things actions are performed on / that are clicked on.
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	# TEST 1c
	start_tile = tile_set_manager.get_tile(Vector2i(4,0))
	dest_tile = tile_set_manager.get_tile(Vector2i(3,4))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 6
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	for o in obstacles:
		o.free()
	
	## TEST 2
	#    0  1  2  3 
	# 0 [ ][x][ ][x]
	# 1 [ ][x][x][x]
	# 2 [ ][x][ ][ ]
	# 3 [ ][ ][ ][ ]
	
	# Place the obstacles (see above)
	for pos in [Vector2i(1,0), Vector2i(1,1) ,Vector2i(1,2), 
				Vector2i(2,1), Vector2i(3,0), Vector2i(3,1)]:
		obstacle = plant_scene.instantiate()
		obstacle.set_on_tile(tile_set_manager.get_tile(pos))
		add_child(obstacle)
	
	# TEST 2a
	start_tile = tile_set_manager.get_tile(Vector2i(2,0))
	dest_tile = tile_set_manager.get_tile(Vector2i(2,2))
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 0
	
	assert_eq(result.size(), exp_len, "Path from %s to %s should be %s." % [start_tile.grid_pos, dest_tile.grid_pos, exp_len])
	
	# TEST 2b
	start_tile = tile_set_manager.get_tile(Vector2i(0,1))
	dest_tile = tile_set_manager.get_tile(Vector2i(3,2)) # End on top of obstacle.
	result = path_finder.find_shortest_path(start_tile, dest_tile)
	exp_len = 7

	for o in obstacles:
		o.free()
