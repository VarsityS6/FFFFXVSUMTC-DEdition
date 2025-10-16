extends Node2D

var dialogue = []
var index = 0
var resume_line_id = ""

# Preload portraits so they are bundled in the export
var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"PlayerSurprise.png": preload("res://portraits/PlayerSurprise.png"),
	"PlayerTriumphant.png": preload("res://portraits/PlayerTriumphant.png"),
	"CConfused.png": preload("res://portraits/CConfused.png"),
	"CTalk.png": preload("res://portraits/CTalk.png"),
	"CHair.png": preload("res://portraits/CHair.png")
}

func _ready():
	dialogue = load_dialogue("res://Dialogue/CHARRAXscene1.json")
	show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

# Jump to a line by its ID
func get_line_by_id(line_id: String) -> Dictionary:
	# Special cases first
	if line_id == "hair_minigame":
		get_tree().change_scene_to_file("res://MiniGames/BrushHair.tscn")
		return {}

	for i in range(dialogue.size()):
		if dialogue[i].has("id") and dialogue[i]["id"] == line_id:
			index = i
			return dialogue[i]
	
	return {}

func show_line():
	if index >= dialogue.size():
		end_dialogue()
		return

	var line = dialogue[index]

	# Skip comments automatically
	if line.has("type") and line["type"] == "comment":
		index += 1
		show_line()
		return

	# Set speaker name and text
	$NameLabel.text = line.get("speaker", "")
	$TextLabel.text = line.get("text", "")

	# Swap portrait
	if line.has("portrait") and line["portrait"] != "":
		$Portrait.texture = preload_portraits.get(line["portrait"], null)
	else:
		$Portrait.texture = null

	# Show choices if present
	if line.has("choices"):
		show_choices(line["choices"])
	else:
		clear_choices()

	# Trigger mini-game if this line has it
	if line.has("minigame"):
		resume_line_id = line.get("resume_id", "")  # save where to resume
		get_tree().change_scene_to_file(line["minigame"])

func show_choices(choices: Array):
	clear_choices()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice["text"]
		var scene_id = choice["scene"] # capture safely
		btn.pressed.connect(func():
			get_line_by_id(scene_id)
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
			# Skip comment lines automatically
			while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
				index += 1
			show_line()

func end_dialogue():
	$NameLabel.text = ""
	$TextLabel.text = ""
	$Portrait.texture = null
	clear_choices()
	print("Dialogue ended")
	get_tree().change_scene_to_file("res://Main Game/Scenes/CheckIn.tscn")
