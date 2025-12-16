class_name PathFinder extends Node

######################################
##           PATH FINDING           ##
###################################### 

@onready var tile_set_manager = get_parent()

# Takes a starting tile and a destination tile, and returns a shortest path between them in the
# form of an array of cartesian coordinates, including the start and end tile coordinates.
# This function implements the A* algorithm.
func find_shortest_path(from_tile: Tile, to_tile: Tile) -> Array[Vector2i]:
	var OPEN : Array[Vector2i] = [from_tile.grid_pos] # The algorithm begins with considering only the start tile.
	var CLOSED: Array[Vector2i] = []
	var G_SCORE : Dictionary = {}
	var F_SCORE : Dictionary = {}
	var CAME_FROM : Dictionary = {}
	
	# Initialize all g scores to be Infinite.
	for tile in tile_set_manager.grid_data:
		G_SCORE.get_or_add(tile, INF)
	
	# Initialize f and g score entries for the starting tile.
	G_SCORE[from_tile.grid_pos] = 0
	F_SCORE[from_tile.grid_pos] = _heuristic(from_tile, to_tile)
	
	while !OPEN.is_empty():
		var cur_tile = _get_lowest_f_cost(OPEN, F_SCORE) # Get tile in OPEN set with minimum f cost.
		
		 # If the considered tile is the destination, reconstruct the final path to it with the "CAME FROM" dictionary and return it.
		if cur_tile == to_tile:
			return _reconstruct_path(CAME_FROM, cur_tile.grid_pos)
		
		OPEN.erase(cur_tile.grid_pos) # Remove the considered tile from OPEN (since we've looked at it now).
		CLOSED.append(cur_tile.grid_pos) # Mark current tile as closed.
		
		for neighbor in tile_set_manager.get_tile_neighbors(cur_tile): # Look at neighbors.
			if neighbor:
				if neighbor == to_tile || !neighbor.plant_on_tile: # Neighbor must be plant-free unless it is the destination.
					
					if CLOSED.has(neighbor.grid_pos): continue # don't examine if it's closed
					
					var tentative_g_score = G_SCORE[cur_tile.grid_pos] + 1 # The cost going the shortest path to the current tile and then to this neighbor.
					if tentative_g_score < G_SCORE.get(neighbor.grid_pos):
						 # If that is better than the previous known cost of reaching that neighboring tile, update the values.
						CAME_FROM[neighbor.grid_pos] = cur_tile.grid_pos  # Set predecessor of neighbor to current tile.
						G_SCORE[neighbor.grid_pos] = tentative_g_score # Set new g score.
						F_SCORE[neighbor.grid_pos] = tentative_g_score + _heuristic(neighbor, to_tile) # Determine and set new f score.
					
						if !OPEN.has(neighbor.grid_pos): OPEN.append(neighbor.grid_pos) # Add neighbor to open.
	
	# No path found.
	return []

######################
## HELPER FUNCTIONS ##
######################
# Given a "came from" dictionary that tracks predecessors of tiles, and cartesian coordinates of the current tile,
# this function reconstructs the current shortest path to that tile and returns this path as an array
# of cartesian coordinates.
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path : Array[Vector2i]= [current]
	
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

# The A* heuristic function. Estimates the distance via the manhattan distance between the tile middle-points.
func _heuristic(from_tile: Tile, to_tile: Tile) -> int:
	return abs(from_tile.grid_pos.x - to_tile.grid_pos.x) + abs(from_tile.grid_pos.y - to_tile.grid_pos.y)

# Given an "open" array which holds cartesian coordinates of tiles that are to be considered, as well as a
# dictionary that is tracking current "f scores" of the tiles, this function returns the tile with the
# lowest f score.
func _get_lowest_f_cost(open_tiles: Array[Vector2i], f_scores: Dictionary) -> Tile:
	var min_cost = INF
	var min_tile = null
	for tile in open_tiles:
		var score = f_scores.get(tile, INF)
		if score < min_cost:
			min_cost = score
			min_tile = tile
	return tile_set_manager.get_tile(min_tile)
