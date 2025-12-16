class_name Pomomon extends Node2D

var on_tile : Tile

# Getter Function for the Sprite.
func get_sprite() -> Sprite2D:
	return get_node("PomomonSprite")

# Takes a Tile object
# and visually places the Pomomon on the corresponding tile on the grid.
func set_on_tile(spot: Tile) -> void:
	global_position = spot.global_position
	on_tile = spot


# This function is not intended to be called manually, ever.
# It is provided to the tile set manager's Tween when 
# the Pomomon is visually moved by it.

# Tween method.
func update_position(new_pos: Vector2) -> void:
	global_position = new_pos

	
