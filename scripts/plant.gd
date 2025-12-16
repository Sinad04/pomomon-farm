class_name Plant extends Node2D

var berry_id : int
var berry_yield : int = 1
var wilted : bool = false
var cur_growth_stage : int = 0
var max_growth_stage : int = 2
var fully_grown : bool = false
var dry_pause_phases : int = 0
var favored_seasons : Array[Enums.SEASONS] = []

var watered : bool:
	get: return on_tile.get_state() == Enums.TILE_STATES.WATERED_FIELD
	
@onready var growth_bar = get_node("GrowthBar")
@onready var sprite = get_node("Texture")

var on_tile : Tile = null

# When the object appears in the scene (usually game screen), it does some adjustments to it's graphics according to it's values.
func _ready() -> void:
	get_sprite().set_texture(Assets.IMAGES["PLANTS"][berry_id])
	
# This function increments the growth stage by one if and only if the plant is
# - not fully grown
# - watered
# If the plant is NOT watered and hasn't been in the previous pause phase either, it wilts.
# If the plant has reached the max growth stage with this call, it becomes fully grown.
func grow() -> void:
	dry_pause_phases += 1
	if watered:
		dry_pause_phases -= 1 # undo the iteration above, otherwise it'll wilt after only one pause phase without watering
		if cur_growth_stage < max_growth_stage:
			cur_growth_stage += 2 if favored_seasons.has(on_tile.tile_set_manager.game_screen.current_season) else 1 # Double Increment if it is a favored season.
			fully_grown = cur_growth_stage >= max_growth_stage
			growth_bar.set_value_no_signal(min(cur_growth_stage, max_growth_stage)) # "min" To avoid broken growth bar on overshoot.
			on_tile.dry_out()
	elif dry_pause_phases >= 2: wilt()


# Set the plant to wilted and set the texture accordingly.
func wilt() -> void:
	wilted = true
	growth_bar.visible = false
	get_sprite().set_texture(Assets.IMAGES["WILTED_PLANT"])


# Takes a Tile object
# and visually places the Plant on the corresponding tile on the grid,
# as well as adding it to the tile's reference
# and updating the tile to count as containing a plant.
func set_on_tile(spot: Tile) -> void:
	global_position = spot.global_position
	on_tile = spot
	spot.plant_on_tile = self

# Return the child node that is the plant texture.
func get_sprite() -> Sprite2D:
	return get_node("Texture")

# Return the growth bar UI node.
func get_growth_bar() -> ProgressBar:
	return get_node("GrowthBar")
