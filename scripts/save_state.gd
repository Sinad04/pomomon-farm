class_name SaveState extends Node

@export var save_state_id : int

var empty : bool = true

# This is a save state object. It's purpose is to read and write a particular json file to store save data in.
# When loading (reading json) it stores the parsed data in it's var fields for other game entities to read and access. 
# Outside of initial application launch, whenever a save state writes to it's var fields it must immediately write to json as well.
# It thus acts as a sort of write-through cache for save data. 

# The default save state that is used when nothing is found in the user directory, or upon resetting a save state.
var default_save_state : Dictionary = {
		"farmState": {
			"rows": 0,
			"cols": 0,
			"unlockedTiles": [
				{
					"x": 1,
					"y": 1,
					"plantedBerryId": null
				}
			]
		},
		"inventory": {
			"berrySeeds": {
				"0": 1,
				},
			"totalBerries": 5
			},
		"timers": {
			"focusMinutes": 25,
			"focusSeconds": 0,
			"breakMinutes": 5,
			"breakSeconds": 0,
			"longBreakMinutes": 15,
			"longBreakSeconds": 0
		},
		"session": {
			"focusPhasesCompleted": 0,
			"currentActivePhase": "BREAK"
		}
	}

var unlocked_tiles : Array 
var total_berries : int 
var seed_inventory : Array 
var focus_phases_completed : int
var current_phase : Enums.PHASES
# [Focus, Short Pause, Long Pause]
var timer_settings : Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
var grid_size : Vector2i

# Upon application startup the save state attempts to find and read it's json file.
func _ready() -> void:
	read_state_from_json()

# Set the save state to the default. This deletes the json file on disk.
func reset_save_state() -> void:
	empty = true
	_apply_save(default_save_state)
	_erase_json_file()

# Read the json file at the path it's expected to be at. ("user://save-state-i.json" where i is this save state's id 1-3.
# After succesful reading, "apply" the resulting dictionary, by writing into this object's fields.
# If reading fails, apply the hardcoded default save state dictionary instead.
func read_state_from_json() -> void:
	var save_path = "user://save-state-%01d.json" % save_state_id # The name format for save state json files is "save-state-i.json" where i is the id.
	if FileAccess.file_exists(save_path):
		var file_content = FileAccess.open(save_path, FileAccess.READ)
		# Parse the JSON as a string and return the result as a Dictionary if succesful, and null otherwise.
		var save_state = JSON.parse_string(file_content.get_as_text())
		
		if save_state is Dictionary:
			empty = false
			_apply_save(save_state)
		else:
			print("Failed to read save file %01d. Using default.." % save_state_id)
			_apply_save(default_save_state)
	else:
		print("Could not find save file %01d. Using default.." % save_state_id)
		_apply_save(default_save_state)

# Delete the save state json file that has this save state object's id.
func _erase_json_file() -> void:
	var save_path = "user://save-state-%01d.json" % save_state_id 
	DirAccess.remove_absolute(save_path)

# Write the fields of this save state object to the corresponding json file.
func write_state_to_json() -> void:
	var save_path = "user://save-state-%01d.json" % save_state_id 
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	var json_content = JSON.stringify(_build_dictionary())
	file.store_string(json_content)

# Private.
# Helper function which turns this save state object's current fields into a Dictionary that 
# complies with the format in which it must be saved in a json file.
func _build_dictionary() -> Dictionary:
	# Prepare a dictionary skeleton.
	var save_state = {"farmState": {"rows": 0, "cols": 0, "unlockedTiles": [] }, "inventory": {"berrySeeds": {}}, "timers": {}, "session": {}}
	
	for tile in unlocked_tiles:
		var cur_tile : Dictionary
		# extract from the "pos" field to match the formatting required for json
		cur_tile.get_or_add("x", tile.get("pos").x)
		cur_tile.get_or_add("y", tile.get("pos").y)

		cur_tile.get_or_add("plantedBerryId", tile.get("plantedBerryId"))
		cur_tile.get_or_add("growthStage", tile.get("growthStage"))
		cur_tile.get_or_add("watered", tile.get("watered"))
		cur_tile.get_or_add("withered", tile.get("withered"))
		save_state["farmState"]["unlockedTiles"].append(cur_tile)
	
	# Write grid size.
	save_state["farmState"]["cols"] = grid_size.x
	save_state["farmState"]["rows"] = grid_size.y
	
	# Write berries.
	save_state["inventory"].get_or_add("totalBerries", total_berries)
	for i in range(3):
		save_state["inventory"]["berrySeeds"].get_or_add(str(i), seed_inventory[i])
	
	# Write timer settings.
	save_state["timers"].get_or_add("focusMinutes", timer_settings[0].x)
	save_state["timers"].get_or_add("focusSeconds", timer_settings[0].y)
	save_state["timers"].get_or_add("breakMinutes", timer_settings[1].x)
	save_state["timers"].get_or_add("breakSeconds", timer_settings[1].y)
	save_state["timers"].get_or_add("longBreakMinutes", timer_settings[2].x)
	save_state["timers"].get_or_add("longBreakSeconds", timer_settings[2].y)
	
	save_state["session"].get_or_add("focusPhasesCompleted", focus_phases_completed)
	match current_phase:
		Enums.PHASES.FOCUS: save_state["session"].get_or_add("currentActivePhase", "FOCUS")
		# "BREAK" is always interpreted as a short pause, because the short-long pause interval is **session**-specific
		Enums.PHASES.SHORT_PAUSE: save_state["session"].get_or_add("currentActivePhase", "BREAK") 
		
	return save_state

# Private.
# Given a dictionary (intended: parsed from json file) this helper 
# function writes all the contained information into this save state object's fields.
func _apply_save(save: Dictionary) -> void:
	# Read unlocked farm tiles.
	unlocked_tiles.clear() # Needed because I'm using append.
	for json_tile in save["farmState"]["unlockedTiles"]:
		var cur_tile : Dictionary
		# coordinates are condensed into one field that holds a 2d int vector, for simpler internal use. field name "pos" 
		cur_tile.get_or_add("pos", Vector2i(json_tile["x"], json_tile["y"]) if json_tile.get("x") && json_tile.get("y") else Vector2i(1,1)) 
		# this one has to be extra clunky because gdscript just happens to see the int 0 as falsy. but we're using 0 as a valid berry id
		if !json_tile.get("plantedBerryId") && json_tile.get("plantedBerryId") != 0: cur_tile.get_or_add("plantedBerryId", null)
		else: cur_tile.get_or_add("plantedBerryId", json_tile.get("plantedBerryId")) 
		cur_tile.get_or_add("growthStage", json_tile["growthStage"] if json_tile.get("growthStage") else 0)
		cur_tile.get_or_add("watered", json_tile["watered"] if json_tile.get("watered") else false)
		cur_tile.get_or_add("withered", json_tile["withered"] if json_tile.get("withered") else false)
		unlocked_tiles.append(cur_tile)
	
	# Read the chosen grid size.
	var cols = save["farmState"].get("cols")
	var rows = save["farmState"].get("rows")

	grid_size = Vector2i(cols, rows)
	
	# Read the inventory.
	total_berries = save["inventory"]["totalBerries"] 
	seed_inventory.clear() # Needed because I'm using append.
	for i in range(3):
		# Write the amount of owned berries into the seed inventory array, or 0 if none is found for the particular id.
		seed_inventory.append(int(save["inventory"]["berrySeeds"][str(i)]) if save["inventory"]["berrySeeds"].get(str(i)) else 0)
	# Store the timer settings as a 2d int vector each. Vector2i(Minutes, Seconds)
	timer_settings[0] = Vector2i(save["timers"]["focusMinutes"], save["timers"]["focusSeconds"])
	timer_settings[1] = Vector2i(save["timers"]["breakMinutes"], save["timers"]["breakSeconds"])
	timer_settings[2] = Vector2i(save["timers"]["longBreakMinutes"], save["timers"]["longBreakSeconds"])
	
	# Completed focus phases and current phase.
	focus_phases_completed = save["session"]["focusPhasesCompleted"]
	match save["session"]["currentActivePhase"]:
		"FOCUS": current_phase = Enums.PHASES.FOCUS
		"BREAK": current_phase = Enums.PHASES.SHORT_PAUSE
		_: current_phase = Enums.PHASES.FOCUS
