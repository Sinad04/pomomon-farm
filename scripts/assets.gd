class_name Assets extends Node

static var plant_A = load("res://resources/PLANT_TYPE_A.png")
static var plant_B = load("res://resources/PLANT_TYPE_B.png")
static var plant_C = load("res://resources/PLANT_TYPE_C.png")
static var plant_wilted = load("res://resources/PLANT_WILTED.png")

static var IMAGES = { "PLANTS": [plant_A, plant_B, plant_C], "WILTED_PLANT" : plant_wilted}

static var TILES = {
	"GREEN": preload("res://resources/greentile.tres"),
	"DRY_FIELD": preload("res://resources/dryfieldtile.tres"),
	"WATERED_FIELD": preload("res://resources/wetfieldtile.tres")
	}
