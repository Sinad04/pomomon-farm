class_name Tile extends Node2D

var tile_set_manager : TileSetManager
var grid_pos : Vector2i
var state : Enums.TILE_STATES
@onready var tile_sprite = get_node("Texture")
var plant_on_tile : Plant = null
var at_edge : bool = false

signal mouse_hovered_on_tile
signal mouse_clicked_on_tile

# Get the enum value of the tile's current state.
func get_state() -> Enums.TILE_STATES:
	return state

# Set the state of the tile to the given enum value, and update the texture.
func set_state(new_state) -> void:
	state = new_state
	_update_texture()

# Return the child node that is the tile texture.
func get_sprite() -> Sprite2D:
	return get_node("Texture")

# Return the collision shape this tile uses for detecting mouse (NOT the Area2D, but the shape itself)
func get_mouse_collision_shape() -> CollisionShape2D:
	return get_node("MouseArea/MouseCollisionShape")

# Private method that is used to check the current value (at calling time) of the 
# tile's state and (re-)set the texture accordingly.
func _update_texture():
	match state:
		Enums.TILE_STATES.GREEN:
			tile_sprite.set("texture", Assets.TILES["GREEN"])
		Enums.TILE_STATES.DRY_FIELD:
			tile_sprite.set("texture", Assets.TILES["DRY_FIELD"])
		Enums.TILE_STATES.WATERED_FIELD:
			tile_sprite.set("texture", Assets.TILES["WATERED_FIELD"])
		_:
			tile_sprite.set("texture", Assets.TILES["GREEN"])


# If currently in watered field state, "dry out" to be in dry field state again.
# This includes "unwatering" a plant that might be on top.
# This function is called by the plant's grow function.
func dry_out() -> void:
	if state == Enums.TILE_STATES.WATERED_FIELD: 
		set_state(Enums.TILE_STATES.DRY_FIELD)
		if plant_on_tile:
			plant_on_tile.watered = false

# Private.
# Called when the mouse enters the Area2d MouseArea of this tile.
func _on_mouse_entered() -> void:
	mouse_hovered_on_tile.emit()

# Private.
# Called when the mouse clicks the Area2d MouseArea of this tile.
func _on_mouse_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_released("Left Click"):
		mouse_clicked_on_tile.emit()


#############
## ACTIONS ##
#############

# Performs the water action on the tile. Conditions are checked by game screen.
func water_tile() -> void:
	plant_on_tile.watered = true
	plant_on_tile.dry_pause_phases = 0
	set_state(Enums.TILE_STATES.WATERED_FIELD)

# Performs the harvest action on the tile. Conditions are checked by game screen.
# This deletes the plant node.
func harvest_tile() -> int:
	var berry_yield = plant_on_tile.berry_yield if !plant_on_tile.wilted else 0
	plant_on_tile.queue_free()
	return berry_yield

# Performs the sow action on the tile. Conditions are checked by game screen.
# This creates a plant node.
func sow_tile(berry_id: int) -> void:
	plant_on_tile = tile_set_manager.spawn_plant_on_tile(grid_pos, berry_id)
