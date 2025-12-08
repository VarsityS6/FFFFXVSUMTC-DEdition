extends Node2D

var dialogue = []
var index = 0
var resume_line_id = ""

# Preload portraits so they are bundled in the export
var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"NinaSurprise.png": preload("res://Portraits/NinaSurprised.png"),
	"NinaExcited.png": preload("res://Portraits/NinaExcited.png"),
	"NinaWorried.png": preload("res://Portraits/NinaWorried.png"),
	"CConfused.png": preload("res://portraits/CConfused.png"),
	"CharraxTalk.png": preload("res://Portraits/Charrax01.png"),
	"CHair": preload("res://portraits/CHair.png"),
	"JimmyPlaceholder.png": preload("res://Portraits/JimmyPlaceholder.png"),
	"TazTalk.png": preload("res://Portraits/TazPlaceholder.png"),
	"TazSulking.png": preload("res://Portraits/TazSulking.PNG")
}

func _ready():
	dialogue = load_dialogue("res://Dialogue/Choice Scene.json")

	if Global.resume_after_minigame:
		Global.resume_after_minigame = false
		get_line_by_id(Global.resume_line_id)
		show_line()
	else:
		show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

# Jump to a line by its ID
func get_line_by_id(line_id: String) -> Dictionary:
	if line_id == "hair_minigame":
		get_tree().change_scene_to_file("res://Main Game/Minigames/BrushMinigame/BrushMinigame.tscn")
		return {}

	for i in range(dialogue.size()):
		if dialogue[i].has("id") and dialogue[i]["id"] == line_id:
			index = i
			return dialogue[i]
	
	return {}

func show_line():
	# Skip comments
	while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
		index += 1
	
	if index >= dialogue.size():
		end_dialogue()
		return

	var line = dialogue[index]

	# ✅ NEW: If this line has "end": true or id == "END", stop dialogue.
	if line.get("end", false) or line.get("id", "") == "END":
		end_dialogue()
		return

	# Speaker and text
	$NameLabel.text = line.get("speaker", "")
	$TextLabel.text = line.get("text", "")

	# Portrait
	if line.has("portrait") and line["portrait"] != "":
		$Portrait.texture = preload_portraits.get(line["portrait"], null)
	else:
		$Portrait.texture = null

	# Choices
	if line.has("choices"):
		show_choices(line["choices"])
	else:
		clear_choices()

	# Minigame check
	if line.has("minigame"):
		resume_line_id = line.get("resume_id", "")
		Global.resume_line_id = resume_line_id
		get_tree().change_scene_to_file(line["minigame"])

func show_choices(choices: Array):
	clear_choices()
	for choice in choices:
		var btn = Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(func():
			if choice.has("scene_change"):
				get_tree().change_scene_to_file(choice["scene_change"])
			else:
				var scene_id = choice["scene"]
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
			while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
				index += 1
			show_line()

func end_dialogue():
	$NameLabel.text = ""
	$TextLabel.text = ""
	$Portrait.texture = null
	clear_choices()
	print("Dialogue ended")
	get_tree().change_scene_to_file("res://Sandbox/Screenshots.tscn")
