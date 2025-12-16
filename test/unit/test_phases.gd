extends GutTest

var game_screen_scene = preload("res://scenes/game_screen.tscn")
var game_screen
var tile_set_manager : TileSetManager
var focus_timer
var short_pause_timer
var long_pause_timer

# Create Game Screen instance and children of it that we'll need for a test.
func before_each():
	game_screen = game_screen_scene.instantiate()
	game_screen.no_auto_load = true
	add_child(game_screen)
	focus_timer = game_screen.focus_timer
	short_pause_timer = game_screen.short_pause_timer
	long_pause_timer = game_screen.long_pause_timer
	tile_set_manager = game_screen.tile_set_manager 
	tile_set_manager.game_screen = game_screen # the field will be null otherwise since it uses an absolute path
	
	game_screen.focus_counter = 0

func after_each():
	game_screen.free()


func test_phase_switch():
	
	## TEST 1 FROM SHORT PAUSE TO FOCUS TO SHORT PAUSE
	
	assert_eq(game_screen.current_phase, Enums.PHASES.SHORT_PAUSE, "Default phase should be short pause.")
	
	game_screen.switch_phase()
	
	assert_eq(game_screen.current_timer, game_screen.focus_timer, "Current timer should be focus.")
	assert_eq(game_screen.current_phase, Enums.PHASES.FOCUS, "Current phase should be focus.")
	
	game_screen.switch_phase()
	
	assert_eq(game_screen.current_timer, game_screen.short_pause_timer, "Current timer should be short pause.")
	assert_eq(game_screen.current_phase, Enums.PHASES.SHORT_PAUSE, "Current phase should be short pause.")

func test_focus_counter():
	
	## TEST 1 FOCUS COUNTER AND LONG BREAK
	
	game_screen.focus_counter = 0
	game_screen.short_pauses_counter = 0
	
	for i in range(4):
		game_screen.switch_phase()
	
	assert_eq(game_screen.short_pauses_counter, 2, "Current short pauses counter should be at 2.")
	
	for i in range(2):
		game_screen.switch_phase()
	assert_eq(game_screen.focus_counter, 3, "Current focus counter should be at 3.")
	assert_eq(game_screen.short_pauses_counter, 0, "Current short pauses counter should be at 0.")
	assert_eq(game_screen.current_phase, Enums.PHASES.LONG_PAUSE, "Current phase should be long pause.")
