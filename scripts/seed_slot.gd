extends PanelContainer

# Seed "slot" in the seed inventory.
# Does not handle the seed logic, only displays it.

@export var id : int

func _ready():
	get_node("MarginContainer2/HBoxContainer/Button").name = str(id)

# Getters for this Container's elements.
func get_name_label() -> Label:
	return get_node("MarginContainer2/HBoxContainer/MarginContainer/HBoxContainer/Name")

func get_amount_label() -> Label:
	return get_node("MarginContainer2/HBoxContainer/MarginContainer/HBoxContainer/Amount")

func get_select_button() -> Button:
	return get_node("MarginContainer2/HBoxContainer/" + str(id))
