extends Node

var resume_after_minigame = false
var resume_line_id = ""
var player: AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	add_child(player)

func play_sfx(name: String):
	stop_sfx()
	var path = "res://Sounds/%s" % name
	if ResourceLoader.exists(path):
		player.stream = load(path)
		player.play()
	else:
		print("SFX not found:", path)

func stop_sfx():
	if player.playing:
		player.stop()
