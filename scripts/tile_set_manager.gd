class_name TileSetManager extends Node2D

var grid_data : Dictionary = {}
@export var grid_size : Vector2i 
var tile_edge_length : int
var tile_scene : PackedScene = preload("res://scenes/tile.tscn")
const margin_factor = 0.75 # change this to affect proportional margin between farm grid and viewport edge.
@onready var marker = get_node("TileMarker")
@onready var pur_marker_scene = preload("res://scenes/purchaseable_marker.tscn")
var pom : Pomomon
@onready var won_marker_scene = preload("res://scenes/wonder_marker.tscn")
@onready var game_screen = get_node("/root/ScreenManager/GameScreen")
@onready var path_finder = get_node("PathFinder")
@onready var wonder_event_handler = get_node("WonderEventHandler")

signal movement_complete

# Takes tile coordinates and returns the tile object associated with them.
func get_tile(tile_coords: Vector2i) -> Tile:
	if grid_data.get(tile_coords):
		return grid_data[tile_coords]
	else: return null

# Return the collision shape the grid currently uses for detecting mouse.
# If there is no grid the shape will have a size of 0.
func get_mouse_collision_shape() -> CollisionShape2D:
	return get_node("MouseArea/MouseCollisionShape")

# Takes tile coordinates and instantiates a new Pomomon node. This Pomomon
# is scaled to be the appropriate size so it "fits" into a tile.
# It is then added as a child node to this tile_set_manager and placed on screen.
func spawn_pomomon_on_tile(pos: Vector2i) -> Pomomon:
	# Fails if there is no grid.
	if grid_data.is_empty():
		print("Generate a grid first!")
		
	var pomomon = preload("res://scenes/pomomon.tscn").instantiate()
	# Scaling proportional to tile edge length.
	var texture_size = pomomon.get_sprite().texture.get_size()
	pomomon.get_sprite().global_scale = Vector2(tile_edge_length / texture_size.x, tile_edge_length / texture_size.y)
	
	add_child(pomomon)
	pomomon.set_on_tile(get_tile(pos))
	return pomomon

# Recursively defined function that animates movement of the Pomomon in this
# set managers pom field. Parameter "index" must be 0 when function is initially called.
# Takes a path which is an array of cartesian coordinates of tiles, and then performs a
# tween animation for each "step" (moving from a tile to a neighbor), updating the Pomomon's
# internal on_tile field for each step as well.
func move_pom_on_path(path: Array[Vector2i], index: int = 0):
	if index < path.size():
		var tile = path[index]
		# Real distance in px between the Pomomon node and the target node (middle of the tile).
		var distance = abs(pom.global_position - get_tile(tile).global_position)
		distance = max(distance.x, distance.y)
		# Set animation duration such that movement is 2 tiles per second.
		var duration = distance / (tile_edge_length * 2)
		
		var tween = create_tween()
		# Tween settings for animation.
		# The tween method is part of the Pomomon object and simply updates the position each call.
		# The starting and end positions are the Pomomon's real current global position and the target
		# tile's real global position. The duration is set above to make movement speed appear as 2 tiles per second.
		tween.tween_method(pom.update_position, pom.global_position, get_tile(tile).global_position, duration)
		
		pom.on_tile = get_tile(tile)
		# The tween when finished calls this function recursively with incremented 
		# index (so the next tile in the path becomes the target)
		tween.tween_callback(move_pom_on_path.bind(path, index+1))
	# Emit signal when movement is completed (base case reached). 
	# This is awaited by the commit_action method of the game screen.
	else: movement_complete.emit() 

# Takes tile coordinates as well as a berry id and instantiate a new Plant node.
# This Plant is scaled to be the appropriate size so it "fits" into a tile.
# The berry id field of the plant is set.
# It is then added as a child node to this tile_set_manager and placed on screen.
func spawn_plant_on_tile(pos: Vector2i, berry_id: int) -> Plant:
	
	var plant = preload("res://scenes/plant.tscn").instantiate()
	# Scaling texture proportional to tile edge length.
	var texture_size = plant.get_sprite().texture.get_size()
	plant.get_sprite().global_scale = Vector2(tile_edge_length / texture_size.x, tile_edge_length / texture_size.y)
	var plant_sprite = plant.get_sprite()
	
	# Scaling and positioning the growth bar.
	var growth_bar = plant.get_growth_bar()
	var plant_width = plant_sprite .texture.get_size().x *  plant_sprite .scale.x
	var plant_height = plant_sprite .texture.get_size().y *  plant_sprite .scale.y
	growth_bar.size.x = plant_width*0.2
	growth_bar.size.y = plant_height*0.4
	growth_bar.position = Vector2(plant.position.x - plant_width*0.25 - growth_bar.size.x*0.5, plant.position.y - plant_height*0.25 - growth_bar.size.y*0.5)
	# Connect half-time signal of focus phase timer to growing function.
	if game_screen: game_screen.get_timer(Enums.PHASES.FOCUS).half_time_over.connect(plant.grow)
	
	
	# Set plant id
	plant.berry_id = berry_id
	# Set growth stage according to config or default value 5.
	plant.max_growth_stage = Configuration.seeds[berry_id].get("growthStages") if Configuration.seeds.size() > berry_id else 5
	# Set yield according to config or default value 1.
	plant.berry_yield = Configuration.seeds[berry_id].get("harvestYield") if Configuration.seeds.size() > berry_id else 1
	var fav_seasons = Configuration.seeds[berry_id].get("favoredSeasons") if Configuration.seeds.size() > berry_id else []
	# Add favored seasons to plant.
	if fav_seasons:
		for season in fav_seasons:
			match season:
				"BREEZY": plant.favored_seasons.append(Enums.SEASONS.BREEZY)
				"WARM": plant.favored_seasons.append(Enums.SEASONS.WARM)
				"RAINY": plant.favored_seasons.append(Enums.SEASONS.RAINY)
				_: print("Season %s not recognized, will not be added to plant." % season) 
	
	add_child(plant)
	plant.growth_bar.max_value = plant.max_growth_stage # Edit growth bar UI element's max value to match plant's.
	plant.set_on_tile(get_tile(pos)) # Set tile physically on grid.
	return plant

# Takes a Tile object and returns all existant orthogonal neighbors in an array of Tile objects.
func get_tile_neighbors(tile: Tile) -> Array[Tile]:
	var neighbors : Array[Tile] = []
	var up = get_tile(Vector2i(tile.grid_pos.x, tile.grid_pos.y-1))
	var down = get_tile(Vector2i(tile.grid_pos.x, tile.grid_pos.y+1))
	var left = get_tile(Vector2i(tile.grid_pos.x-1, tile.grid_pos.y))
	var right = get_tile(Vector2i(tile.grid_pos.x+1, tile.grid_pos.y))
	
	if up: neighbors.append(up)
	if down: neighbors.append(down)
	if left: neighbors.append(left)
	if right: neighbors.append(right)
	
	return neighbors


# Iteratively determine which tiles of the current grid (child of this node) meet the criteria to be
# considered purchaseable, and for each one that does instantiate and place a purchase marker object on the tile.
func mark_purchaseable_tiles() -> Array:
	var purchasable : Array = []
	for key in grid_data.keys():
		var tile = grid_data[key]
		if tile.get_state() == Enums.TILE_STATES.GREEN && !tile.at_edge:
			for neighbor in get_tile_neighbors(tile):
				# If there is at least one neighbor that is already field.
				if neighbor.get_state() != Enums.TILE_STATES.GREEN:
					var pur_marker = pur_marker_scene.instantiate()
					# Scale it correctly.
					var marker_texture_size = pur_marker.texture.get_size() 
					pur_marker.global_scale = Vector2(tile_edge_length / marker_texture_size.x, tile_edge_length / marker_texture_size.y)
					add_child(pur_marker)
					pur_marker.tile = tile # No reason to do this beside making unit tests way easier.
					purchasable.append(pur_marker) # To be able to delete them all later.
					# Connect the purchase tile function of the marker object to the tile's clicked signal.
					tile.mouse_clicked_on_tile.connect(pur_marker.purchase_tile)
					pur_marker.global_position = tile.global_position
					break
	return purchasable

# Iteratively checks each tile and wilts the plant on top of it if it exists.
# Mainly intended to be used for the season switch.
func wilt_all_plants():
	if grid_data.is_empty(): return # Don't do anything if there's no grid.
	var cur_tile
	for x in range(1, grid_size.x-2): # No need to consider edge tiles.
		for y in range(1, grid_size.y-2):
			cur_tile = get_tile(Vector2i(x,y))
			if cur_tile.plant_on_tile:
				cur_tile.plant_on_tile.wilt()
				cur_tile.set_state(Enums.TILE_STATES.DRY_FIELD)
				cur_tile.plant_on_tile.watered = false

func initialize_grid(unlocked: Array) -> void:
	# Determine ideal tile size. The tiles have to be square, so the edge length will be
	# the minimum of the longest possible tile-height for the grid to stay fully 
	# on screen AND the longest possible tile-width for the grid to stay fully on screen.
	var max_tile_width = (get_viewport_rect().size.x*margin_factor) / grid_size.x
	var max_tile_height = (get_viewport_rect().size.y*margin_factor) / grid_size.y
	tile_edge_length = min(max_tile_width, max_tile_height)
	# Set Mouse Collision Shape (of entire grid) dimensions according to grid dimensions.
	get_mouse_collision_shape().get_shape().size = tile_edge_length*grid_size
	# Inform the wonder event handler how big the grid is.
	wonder_event_handler.grid_size = grid_size
	# Connect the wonder event handler's signal to the function here that performs the wonder event.
	wonder_event_handler.wonder_event.connect(_wonder_event)
	# Adjust marker size to tile size.
	if marker:
		var marker_texture_size = marker.texture.get_size() 
		marker.global_scale = Vector2(tile_edge_length / marker_texture_size.x, tile_edge_length / marker_texture_size.y)
	# Connect focus half-time to the wonder event query occuring.
	if game_screen: game_screen.get_timer(Enums.PHASES.FOCUS).half_time_over.connect(wonder_event_handler.connect_to_server)
	# Generate the tile objects as child nodes and store them in the dictionary grid_data.
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var tile_instance = tile_scene.instantiate()
			if tile_instance:
				# Set tile objects position (center of tile) in game screen.
				tile_instance.position = tile_edge_length * Vector2i(x, y)
				# Set grid position attribute.
				tile_instance.grid_pos = Vector2i(x,y)
				# Give reference to self.
				tile_instance.tile_set_manager = self
				# Set whether it's an edge tile.
				tile_instance.at_edge = x == 0 || y == 0 || x == grid_size.x-1 || y == grid_size.y-1
				# Connect the signal for mouse hover to the set marker function in this tile manager, so the marker can be set on this tile.
				tile_instance.mouse_hovered_on_tile.connect(_set_marker_on_tile.bind(tile_instance))
				# Connect the signal for mouse click to the commit action function in the game screen.
				if game_screen: tile_instance.mouse_clicked_on_tile.connect(game_screen.commit_action.bind(tile_instance))
				# adjust the position such that 
				# the middle of the grid is the position of the tile_set_manager
				tile_instance.position -= 0.5*Vector2(grid_size.x, grid_size.y)*tile_edge_length
				tile_instance.position += 0.5*Vector2(tile_edge_length, tile_edge_length)
				# set sprite global scale according to needed tile size
				var tile_sprite = tile_instance.get_sprite()
				var texture_size = tile_sprite.texture.get_size()
				tile_sprite.global_scale = Vector2(tile_edge_length / texture_size.x, tile_edge_length / texture_size.y)
				
				# set mouse collision shape global scale according to needed tile size
				var tile_shape = tile_instance.get_mouse_collision_shape()
				var tile_shape_size = tile_shape.get_shape().get_rect().size
				tile_shape.global_scale = Vector2(tile_edge_length / tile_shape_size.x, tile_edge_length / tile_shape_size.y)
				
				# add this tile as a child of this tile set manager and add it to the dictionary
				add_child(tile_instance)
				grid_data[Vector2i(x,y)] = tile_instance
	# Examine and edit provided tiles that should be unlocked.
	for tile in unlocked:
		var cur_tile = get_tile(tile["pos"])
		if cur_tile:
			cur_tile.set_state(Enums.TILE_STATES.WATERED_FIELD if tile["watered"] else Enums.TILE_STATES.DRY_FIELD)
			if tile["plantedBerryId"] || tile["plantedBerryId"] == 0: 
				var plant = spawn_plant_on_tile(cur_tile.grid_pos, tile["plantedBerryId"])
				plant.cur_growth_stage = int(tile["growthStage"])
				plant.growth_bar.set_value_no_signal(plant.cur_growth_stage)
				if plant.cur_growth_stage >= plant.max_growth_stage: plant.fully_grown = true
				if tile["watered"]: cur_tile.water_tile()
				if tile["withered"]: plant.wilt()
	pom = spawn_pomomon_on_tile(Vector2i(0,0))

# Private.
# Executes the "wonder event" on the tile at given cartesian coordinate, by placing
# wonder marker objects on the tile if and only if it is eligible, and then invoking growth of the plant.
# Tiles are eligible if they contain a plant that can grow i.e. is not fully grown nor wilted.
# !! This method also waters the tile, resetting the "dry pause phases" counter.
# The above is done for the given tile's existing orthogonal neighbors as well.
func _wonder_event(pos: Vector2i):
	var target_tile = get_tile(pos)
	var neighbor_tiles = get_tile_neighbors(target_tile)
	neighbor_tiles.append(target_tile)
	for tile in neighbor_tiles:
		if tile.plant_on_tile && !tile.plant_on_tile.wilted && !tile.plant_on_tile.fully_grown:
			var wonder_marker = won_marker_scene.instantiate()
			add_child(wonder_marker)
			# Scale and place the wonder marker accordingly.
			wonder_marker.global_position = tile.global_position
			var marker_texture_size = wonder_marker.texture.get_size() 
			wonder_marker.global_scale = Vector2(tile_edge_length / marker_texture_size.x, tile_edge_length / marker_texture_size.y)
			
			tile.water_tile() 
			tile.plant_on_tile.grow()

# private.
# places the marker "TileMarker" on the provided tile.
# this function is connected to the signal "mouse_hovered_on_tile" of every tile instance.
func _set_marker_on_tile(tile: Tile) -> void:
	marker.global_position = tile.global_position

# private.
# makes marker invisible. called when mouse EXITS the tile set managers mouse collision area
func _hide_marker() -> void:
	marker.visible = false

# private.
# makes marker visible. called when mouse ENTERS the tile set managers mouse collision area
func _show_marker() -> void:
	marker.visible = true
