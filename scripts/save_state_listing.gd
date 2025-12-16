class_name SaveStateListing extends PanelContainer

# A save state listing in the start screen.

@export var id : int

var save_state : SaveState

@onready var phase_label = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/ActivePhase")
@onready var compl_foc_label = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/CompletedFoc")
@onready var id_label = get_node("MarginContainer/VBoxContainer/ID")
@onready var owned_berries_label = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/OwnedBerries")
@onready var grid_size_label = get_node("MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GridSize")
@onready var empty_label = get_node("MarginContainer/VBoxContainer/Empty")
@onready var del_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/Delete")
@onready var conf_del_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/ConfirmDelete")

signal load_save_state_pressed(state: SaveState)

func _ready() -> void:
	_update_display()

# Update the text of this listing to match the save state object it represents. 
# Especially the ID and some noteworthy identifying data is displayed.
func _update_display() -> void:
	save_state = get_node("/root/ScreenManager/SaveState%01d" % id)
	id_label.text = "SAVE STATE #%01d" % save_state.save_state_id
	owned_berries_label.text = "Owned Berries: %s" % save_state.total_berries  
	empty_label.visible = save_state.empty 
	grid_size_label.visible = false
	if !save_state.empty:
		grid_size_label.visible = true
		grid_size_label.text = "Grid Size: "
		match save_state.grid_size:
			Vector2i(3,3): grid_size_label.text += "Tiny"
			Vector2i(5,4): grid_size_label.text += "Small"
			Vector2i(8,5): grid_size_label.text += "Medium"
			Vector2i(11,7): grid_size_label.text += "Large"
			Vector2i(14,8): grid_size_label.text += "Huge"
			_: grid_size_label.text += "Unknown"
	
	match save_state.current_phase:
		Enums.PHASES.FOCUS: phase_label.text = "Current Phase: Focus"
		Enums.PHASES.SHORT_PAUSE: phase_label.text = "Current Phase: Break"
		Enums.PHASES.LONG_PAUSE: phase_label.text = "Current Phase: Break (Long)"
	compl_foc_label.text = "Completed Focus Phases: " + str(save_state.focus_phases_completed)

# Show the confirm delete button. Called when delete is pressed.
func show_conf_del() -> void:
	del_button.visible = false
	conf_del_button.visible = true

# Called when confirm delete is pressed. Resets the associated save state object.
func reset_save_state() -> void:
	save_state.reset_save_state()
	_update_display()

# Called when the load button is pressed. Emits a signal which is listened 
# to by the Screen Manager and will cause it to switch to the game screen, 
# passing this listing's save state object.
func load_save_state() -> void:
	load_save_state_pressed.emit(save_state)

# Getters for this Container's elements.
func get_load_button() -> Button:
	return get_node("VBoxContainer/HBoxContainer/Load")

func get_del_button() -> Button:
	return get_node("VBoxContainer/HBoxContainer/Delete")

func get_confdel_button() -> Button:
	return get_node("VBoxContainer/HBoxContainer/ConfirmDelete")
