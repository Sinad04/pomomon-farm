extends Sprite2D

# This marker is instantiated and placed to highlight which tiles can be bought during "purchase mode".

# What tile it's marking. This Info isn't really needed outside of testing.
var tile : Tile = null

signal purchased

# Called by the tile this marker is on top of, when that tile is clicked.
func purchase_tile():
	if tile:
		tile.set_state(Enums.TILE_STATES.DRY_FIELD)
		purchased.emit()
