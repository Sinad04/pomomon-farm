class_name TileListing extends PanelContainer

# A seed listing in the seed shop.

@onready var cur_price : int = Configuration.base_tile_cost
@onready var price_label : Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/Price")
signal purchase(price: int)

# This is called when the buy button is pressed.
func _purchase():
	purchase.emit(cur_price) 

func _ready():
	update_display()

func update_display():
	price_label.text = "Price: " + str(cur_price)

# Getters for this Container's elements.
func get_price_label() -> Label:
	return get_node("MarginContainer/VBoxContainer/HBoxContainer/Price")

func get_buy_button() -> Button:
	return get_node("MarginContainer/VBoxContainer/HBoxContainer/BuyButtonContainer/Buy")
