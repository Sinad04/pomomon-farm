class_name AudioManager extends Node

# This node handles all game audio. Any sounds that can play are direct children of this node and should only
# be managed or played by this node.

# Play an audio if it can be found as a child of this manager. Name has to be the name of the audio node.
func play_audio(audio_name: String) -> void:
	var sound = get_node(audio_name)
	if sound:
		sound.play()
	else: 
		print("%s was not found!" % [audio_name]) 
