extends Node

@onready var wonder_url = Configuration.server_url
@export var enabled : bool = true

var socket = WebSocketPeer.new()

# Set by the tile set manager when the grid is initialized.
var grid_size : Vector2i 

var request_dictionary = {
	"messageType": "WONDER_REQUEST", 
	"maxFieldSize": {
	"minX": 1, # always 1
	"maxX": 1,
	"minY": 1, 
	"maxY": 1}}

var sent = false
var received = false

signal wonder_event(tile: Vector2i)

# Processing / Polling is off unless there's an active connection or connection attempt going on.
func _ready():
	set_process(false)

# Try a connection to the wonder event server url as specified in the config.
# Send a wonder request if connection possible.
func connect_to_server():
	if !enabled: return
	set_process(true)
	var err = socket.connect_to_url(wonder_url)
	if err == OK: 
		print("Connecting to wonder server...")
	else: 
		print("Can't connect to wonder server.")
		set_process(false)


# Takes the grid size and builds a dictionary that conforms
# to the json format the request must be in, including
# the appropriate max values for x and y.
func _build_request() -> Dictionary:
	var request = request_dictionary
	# -1 because 0 indexed and another -1 because edge tiles not included
	request["maxFieldSize"]["maxX"] = (grid_size.x-2) 
	request["maxFieldSize"]["maxY"] = (grid_size.y-2)
	
	return request

# Examine a response in the form of a dictionary and react accordingly.
func check_response(response: Dictionary):
	match response["messageType"]:
		"WONDER_GRANTED":
			var x = int(response["position"].get("x"))
			var y = int(response["position"].get("y"))
			wonder_event.emit(Vector2i(x, y))
			print("Wonder event at (%01d, %01d)." % [x,y])
		"NO_WONDER": print("No wonder event.")
		"REQUEST_ERROR":
			print(response["error"])

# Polling the socket and managing this node depending on socket state while a connection is in process.
func _process(_delta):
	
	socket.poll()
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if !sent:  # Send exactly once.
			socket.send_text(JSON.stringify(_build_request()))
			sent = true

		if received: socket.close() # Once the server response is received, close the connection.

		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				var packet_raw_text = packet.get_string_from_utf8()
				var packet_data = JSON.parse_string(packet_raw_text)
				if packet_data is Dictionary:
					check_response(packet_data)
			received = true
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code() # unclean disconnect if code is -1
		print("Connection to wonder server closed with code: %01d" % code)
		sent = false
		received = false
		set_process(false)
