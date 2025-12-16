extends GutTest


var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var tile_set_manager : TileSetManager
var plant_scene = preload("res://scenes/plant.tscn")
var tile_scene = preload("res://scenes/tile.tscn")

# Create Game Screen instance and children of it that we'll need for a test.
func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	tile_set_manager = game_screen.tile_set_manager 
	tile_set_manager.game_screen = game_screen # the field will be null otherwise since it uses an absolute path
	
	game_screen.focus_counter = 0

func after_each():
	game_screen.free()

func test_season_switch():
	
	## TEST 1 NEWLY LOADED
	assert_eq(game_screen.current_season, Enums.SEASONS.BREEZY, "Season by default should be breezy.")
	
	## TEST 2
	
	for i in range(24): # Starting in pause phase switch phase 24 times, ending up in a pause phase with 12 focus phases completed.
		game_screen.switch_phase()
	assert_eq(game_screen.current_season, Enums.SEASONS.BREEZY, "After 12 focus phases BEFORE next pause phase ends season should still be BREEZY")
	
	game_screen.switch_phase()
	assert_eq(game_screen.current_season, Enums.SEASONS.WARM, "After 12 focus phases AFTER next pause phase ends season should be WARM")

func test_favored_seasons():
	
	var growth_stage_before_a
	var growth_stage_before_b
	
	var plant_a : Plant = plant_scene.instantiate()
	var plant_b : Plant = plant_scene.instantiate()
	var tile_a : Tile = tile_scene.instantiate()
	var tile_b : Tile = tile_scene.instantiate()
	
	add_child(plant_a)
	add_child(plant_b)
	add_child(tile_a)
	add_child(tile_b)
	
	tile_a.tile_set_manager = tile_set_manager
	tile_b.tile_set_manager = tile_set_manager
	
	# Prepare 2 plants a and b. a has favored seasons, b does not.
	
	plant_a.cur_growth_stage = 0
	plant_a.max_growth_stage = 9999
	plant_a.set_on_tile(tile_a)
	plant_a.favored_seasons = [Enums.SEASONS.BREEZY, Enums.SEASONS.RAINY]
	plant_b.cur_growth_stage = 0
	plant_b.max_growth_stage = 9999
	plant_b.set_on_tile(tile_b)
	plant_b.favored_seasons = []
	
	## TEST 1 BREEZY
	game_screen.current_season = Enums.SEASONS.BREEZY
	
	# Values to compare before / after
	growth_stage_before_a = plant_a.cur_growth_stage
	growth_stage_before_b = plant_b.cur_growth_stage
	
	# Simulate plant growth
	tile_a.water_tile()
	tile_b.water_tile()
	plant_a.grow()
	plant_b.grow()
	
	assert_eq(plant_a.cur_growth_stage, growth_stage_before_a+2, "Plant A growth stage should increment by 2 during BREEZY.")
	assert_eq(plant_b.cur_growth_stage, growth_stage_before_b+1, "Plant B growth stage should increment by 1 during BREEZY.")
	
	## TEST 2 WARM
	game_screen.current_season = Enums.SEASONS.WARM

	# Values to compare before / after
	growth_stage_before_a = plant_a.cur_growth_stage
	growth_stage_before_b = plant_b.cur_growth_stage
	
	# Simulate plant growth
	tile_a.water_tile()
	tile_b.water_tile()
	plant_a.grow()
	plant_b.grow()
	
	assert_eq(plant_a.cur_growth_stage, growth_stage_before_a+1, "Plant A growth stage should increment by 1 during WARM.")
	assert_eq(plant_b.cur_growth_stage, growth_stage_before_b+1, "Plant B growth stage should increment by 1 during WARM.")
	
	## TEST 3
	
	game_screen.current_season = Enums.SEASONS.RAINY
	
	# Values to compare before / after
	growth_stage_before_a = plant_a.cur_growth_stage
	growth_stage_before_b = plant_b.cur_growth_stage
	
	# Simulate plant growth
	tile_a.water_tile()
	tile_b.water_tile()
	plant_a.grow()
	plant_b.grow()
	
	assert_eq(plant_a.cur_growth_stage, growth_stage_before_a+2, "Plant A growth stage should increment by 2 during RAINY.")
	assert_eq(plant_b.cur_growth_stage, growth_stage_before_b+1, "Plant B growth stage should increment by 1 during RAINY.")
	
	## EPILOGUE
	
	plant_a.free()
	plant_b.free()
	tile_a.free()
	tile_b.free()
