class_name SeedListing extends PanelContainer

# A seed listing in the seed shop.

var price : int
@export var id : int
var seed_name : String
signal purchase(id: int, price: int)

func _ready():
	get_node("MarginContainer/VBoxContainer/HBoxContainer/BuyButtonContainer/Buy").name = str(id)

# This is called when the buy button is pressed.
func _purchase() :
	# Listened to by the game screen, which uses these two 
	# integers to perform the correct transaction (if possible).
	purchase.emit(id, price) 

# Getters for this Container's elements.
func get_name_label() -> Label:
	return get_node("MarginContainer/VBoxContainer/HBoxContainer/Name")

func get_price_label() -> Label:
	return get_node("MarginContainer/VBoxContainer/HBoxContainer/Price")

func get_buy_button() -> Button:
	return get_node("MarginContainer/VBoxContainer/HBoxContainer/BuyButtonContainer/" + str(id))

func get_desc_label() -> Label:
	return get_node("MarginContainer/VBoxContainer/MarginContainer/Desc")
