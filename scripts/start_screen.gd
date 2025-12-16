class_name StartScreen extends Node 

@onready var save_state_list = get_node("SaveStateList")
@onready var start_button = get_node("StartButton")
@onready var field_size_list = get_node("PickFieldSize")
@onready var field_size_buttons = [get_node("PickFieldSize/VBoxContainer/MarginContainer2/HBoxContainer/Tiny"),
get_node("PickFieldSize/VBoxContainer/MarginContainer2/HBoxContainer/Small"),
get_node("PickFieldSize/VBoxContainer/MarginContainer2/HBoxContainer/Medium"),
get_node("PickFieldSize/VBoxContainer/MarginContainer2/HBoxContainer/Large"),
get_node("PickFieldSize/VBoxContainer/MarginContainer2/HBoxContainer/Huge")]

# Listened to by the screen manager, connected to it's load game screen method.
signal load_save_state(save_state: SaveState, grid_size: Vector2i)

# Private.
# Triggered by the start button being clicked, displays the save state listing.
func _display_save_states() -> void:
	start_button.visible = false
	field_size_list.visible = false
	save_state_list.visible = true

func select_save_state(save_state: SaveState):
	if save_state.empty:
		# Connect field size button pressed to loading the save state.
		field_size_buttons[0].pressed.connect(load_save_state.emit.bind(save_state, Vector2i(3,3)))
		field_size_buttons[1].pressed.connect(load_save_state.emit.bind(save_state, Vector2i(5,4)))
		field_size_buttons[2].pressed.connect(load_save_state.emit.bind(save_state, Vector2i(8,5)))
		field_size_buttons[3].pressed.connect(load_save_state.emit.bind(save_state, Vector2i(11,7)))
		field_size_buttons[4].pressed.connect(load_save_state.emit.bind(save_state, Vector2i(14,8)))
		_display_field_size_selection()
	else:
		# grid size already known inside save state, (0,0) is falsy and used here as "no grid size info needed/provided"
		load_save_state.emit(save_state, Vector2i.ZERO) 



func _display_field_size_selection():
	save_state_list.visible = false
	field_size_list.visible = true

func get_save_state_listings() -> Array:
	return [get_node("SaveStateList/HBoxContainer/SaveStateListing1"), 
	get_node("SaveStateList/HBoxContainer/SaveStateListing2"), 
	get_node("SaveStateList/HBoxContainer/SaveStateListing3")]
