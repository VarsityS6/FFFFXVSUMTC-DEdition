extends Node2D

var dialogue = []
var index = 0

# ✅ Preload portraits so they are guaranteed to be bundled in the export
var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"PlayerSurprise.png": preload("res://portraits/PlayerSurprise.png"),
	"PlayerTriumphant.png": preload("res://portraits/PlayerTriumphant.png"),
	"CConfused.png": preload("res://portraits/CConfused.png"),
	"CTalk.png": preload("res://portraits/CTalk.png"),
	"CHair.png": preload("res://portraits/CHair.png")
	
}

func _ready():
	dialogue = load_dialogue("res://Dialogue/FirstScene.json")
	show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())
	
	if not FileAccess.file_exists(path):
		push_error("Dialogue file not found: " + path)
		return JSON.parse_string(file.get_as_text())

func show_line():
	if index >= dialogue.size():
		end_dialogue()
		return
	
	var line = dialogue[index]

	# Stop if line is the end marker
	if line.has("text") and line["text"] == "[End of dialogue]":
		end_dialogue()
		return

	# Set speaker name and text
	$NameLabel.text = line.get("speaker", "")
	$TextLabel.text = line.get("text", "")

	# ✅ Swap portrait loading to use preloaded dictionary
	if line.has("portrait") and line["portrait"] != "":
		if preload_portraits.has(line["portrait"]):
			$Portrait.texture = preload_portraits[line["portrait"]]
		else:
			print("Portrait missing from preload: ", line["portrait"])
			$Portrait.texture = null
	else:
		$Portrait.texture = null 

	if line.has("choices"):
		show_choices(line["choices"])
	else:
		clear_choices()

func show_choices(choices: Array):
	clear_choices()
	for c in choices:
		var btn = Button.new()
		btn.text = c["text"]
		btn.pressed.connect(func():
			index = c["next"]
			show_line()
		)
		$Choices.add_child(btn)

func clear_choices():
	for child in $Choices.get_children():
		child.queue_free()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if not dialogue[index].has("choices"):
			index += 1
			show_line()

func end_dialogue():
	$NameLabel.text = ""
	$TextLabel.text = ""
	$Portrait.texture = null
	clear_choices()
	print("Dialogue ended")
	get_tree().change_scene_to_file("res://Main Game/CheckIn.tscn") 
