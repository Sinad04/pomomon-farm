class_name Configuration extends Node



const config_path = "user://config.json"

# The "default" configuration that is to be applied if nothing is found in the user directory.
var default_config = {"server":{
	"url":"wss://pomomon.farm/ws"
	},
	"fieldExtension": {
		"baseCost": 100,
		"increase": 1.2
	},
	"berries" : 
	[{"id":0, "name":"Mirthberry", "growthStages":3, "harvestYield":10, "seedCost":5, "favoredSeasons": ["BREEZY"]},
	{"id":1, "name":"Tealberry", "growthStages":4, "harvestYield":18, "seedCost":8, "favoredSeasons": ["RAINY", "WARM"]},
	{"id":2, "name":"Boonberry", "growthStages":4, "harvestYield":40, "seedCost":15, "favoredSeasons": []}
	]}


# Private.
# Attempt to read the configuration file at the config path.
# This function catches errors that are syntactic, such as 
# invalid JSON or a missing file / incorrect file path.
func read_config_file():
	print("reading config file...")
	if FileAccess.file_exists(config_path):
		
		var file_content = FileAccess.open(config_path, FileAccess.READ)
		# Parse the JSON as a string and return the result as a Dictionary if succesful, and null otherwise.
		var config = JSON.parse_string(file_content.get_as_text())
		file_content.close()
		
		if config is Dictionary:
			_apply_config(config) 
		else:
			print("Failed to read config file. Using default..")
			_apply_config(default_config)
	else:
		print("Could not find config file. Using default..")
		_apply_config(default_config)

# Private.
# Applies a config which is given in form of a dictionary.
# This function catches errors that are semantic, such as integers that are 
# out of bounds for our purposes, or missing entries.
func _apply_config(config: Dictionary):
	# Parse berry entries if they exist, otherwise use defaults.
	if config.get("berries"):
		if config["berries"].size() > 3:
			print("More than 3 berries detected in config. IDs above 2 will be ignored.")
		seeds.clear() # needed because I'm using append
		var id_tracker = [false,false,false] # Keep track of which valid ids have been used in this config.
		for i in range(3):
			# Look at entry i if it exists, otherwise set it to null so it gets skipped.
			var cur_berry = config["berries"][i] if config["berries"].size() > i else null
			if cur_berry && int(cur_berry.get("id")) in range(3): # check if entry id is an integer 0-2
				# If the id was already used, skip this entry and opt for default.
				if id_tracker[cur_berry["id"]]:
					print("Duplicate id detected for berry entry %01d in config. Using default instead." % (i+1))
					seeds.append(default_config["berries"].get(i))
					continue
			
				# Convert the number entries to int, since JSON's Number type is automatically parsed as a float.
				for key in cur_berry.keys():
					if key!="name" && key!="favoredSeasons": cur_berry[key] = int(cur_berry[key])
				# Tick off the id.
				id_tracker[cur_berry["id"]] = true
				# Enforce fallback or default values for omitted fields.
				cur_berry.get_or_add("name", "Nameless Seed")
				cur_berry.get_or_add("growthStages", 2)
				cur_berry.get_or_add("harvestYield", 30)
				cur_berry.get_or_add("seedCost", 10)
				cur_berry.get_or_add("favoredSeasons", [])
			
				seeds.append(cur_berry)
			else: 
				print("Berry entry #%01d missing in config (3 total expected with ids 0-2). Using default for entry %01d.." % [i+1,i+1])
				seeds.append(default_config["berries"].get(i))
	else:
		for i in range(3):
			seeds.append(default_config["berries"][i])
	# Rudimentary checks for completeness of the config outside of berry entries, and their failsafes.
	if config.get("server"):
		server_url = config["server"].get("url")
	else:
		server_url = default_config["server"]["url"]
		print("no url specified in config, using default...")
	if config.get("fieldExtension") && config["fieldExtension"].get("baseCost"):
		base_tile_cost = config["fieldExtension"].get("baseCost")
	else:
		base_tile_cost = default_config["fieldExtension"]["baseCost"]
		print("no base tile cost specified in config, using default...")
	if config.get("fieldExtension") && config["fieldExtension"].get("increase"):
		tile_cost_increase = config["fieldExtension"].get("increase")
	else:
		tile_cost_increase = default_config["fieldExtension"]["increase"]
		print("no tile cost increase specified in config, using default...")

# ACTUAL CONFIGURATION
# These static fields are accessed by the corresponding game entities.
static var seeds : Array[Dictionary]
static var server_url : String
static var base_tile_cost : int
static var tile_cost_increase : float
