extends GutTest

var config_loader_scene = preload("res://scenes/config_loader.tscn")

var config_file : FileAccess
var config_dictionary : Dictionary

var config_loader : Configuration

func before_all():
	config_loader = config_loader_scene.instantiate()
	add_child(config_loader)

func before_each():
	DirAccess.remove_absolute("user://config.json")

func test_valid_config_loading():
	
	config_dictionary = {"server":{
		"url":"ws://localhost:50"
	},
	"fieldExtension": {
		"baseCost": 300,
		"increase": 1.7
	},
	"berries" : 
	[{"id":0, "name":"Testberry", "growthStages":1, "harvestYield":1, "seedCost":1, "favoredSeasons": []},
	{"id":1, "name":"Examineberry", "growthStages":2, "harvestYield":2, "seedCost":2, "favoredSeasons": []},
	{"id":2, "name":"Assertberry", "growthStages":3, "harvestYield":3, "seedCost":3, "favoredSeasons": []}
	]}
	
	# Write a valid config file.
	config_file = FileAccess.open("user://config.json", FileAccess.WRITE)
	config_file.store_string(JSON.stringify(config_dictionary))
	config_file.close()
	
	# Make the loader read the valid config file.
	config_loader.read_config_file()
	
	assert_eq(Configuration.server_url, "ws://localhost:50", "Configuration static field server_url should be ws://localhost:50")
	assert_eq(Configuration.seeds[0], config_dictionary["berries"][0], "Configuration static seed field 0 should match expected Dictionary")
	assert_eq(Configuration.seeds[1], config_dictionary["berries"][1], "Configuration static seed field 1 should match expected Dictionary")
	assert_eq(Configuration.seeds[2], config_dictionary["berries"][2], "Configuration static seed field 2 should match expected Dictionary")
	assert_eq(Configuration.base_tile_cost, 300, "Configuration static field base_tile_cost should equal 300")
	assert_eq(Configuration.tile_cost_increase, 1.7, "Configuration static field tile_cost_increase should equal 1.7")

func test_invalid_config_loading():
	
	# Write an intentionally invalid config file.
	config_file = FileAccess.open("user://config.json", FileAccess.WRITE)
	config_file.store_string("null")
	config_file.close()
	
	# Make the loader read the valid config file.
	config_loader.read_config_file()
	
	assert_eq(Configuration.server_url, config_loader.default_config["server"]["url"], "Configuration static field server_url should be default value")
	for i in range(3):
		assert_eq(Configuration.seeds[i], config_loader.default_config["berries"][i], "Configuration static seed field %01d should be default value" % i)
	assert_eq(Configuration.base_tile_cost, config_loader.default_config["fieldExtension"]["baseCost"], "Configuration static field base_tile_cost should be default value")
	assert_eq(Configuration.tile_cost_increase, config_loader.default_config["fieldExtension"]["increase"], "Configuration static field tile_cost_increase should be default value")
