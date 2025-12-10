extends Node2D

var dialogue = []
var index = 0
var resume_line_id = ""

var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"NinaSurprised.png": preload("res://portraits/NinaSurprised.png"),
	"NinaExcited.png": preload("res://portraits/NinaExcited.png"),
	"TazSulking.png": preload("res://portraits/TazSulking.PNG"),
	"TazTalk.png": preload("res://portraits/TazPlaceholder.png"),
}

@onready var sfx: AudioStreamPlayer = $"BG Music"

func _ready():
	if sfx.stream:
		sfx.stream.loop = true
		sfx.play()
	dialogue = load_dialogue("res://Dialogue/TAZscene2.json")
	if Global.resume_after_minigame:
		Global.resume_after_minigame = false
		get_line_by_id(Global.resume_line_id)
		show_line()
	else:
		show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func get_line_by_id(line_id: String) -> Dictionary:
	if line_id == "coffee_minigame":
		get_tree().change_scene_to_file("res://Main Game/Minigames/CoffeeMinigame/CoffeeMinigame.tscn")
		return {}

	for i in range(dialogue.size()):
		if dialogue[i].has("id") and dialogue[i]["id"] == line_id:
			index = i
			return dialogue[i]
	
	return {}

func show_line():
	while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
		index += 1

	if index >= dialogue.size():
		end_dialogue()
		return

	var line = dialogue[index]

	if line.get("end", false) or line.get("id", "") == "END":
		end_dialogue()
		return

	$NameLabel.text = line.get("speaker", "")
	$TextLabel.text = line.get("text", "")

	if line.has("portrait") and line["portrait"] != "":
		$Portrait.texture = preload_portraits.get(line["portrait"], null)
	else:
		$Portrait.texture = null

	if line.has("sfx") and line["sfx"] != "":
		Global.play_sfx(line["sfx"])

	if line.has("choices"):
		show_choices(line["choices"])
	else:
		clear_choices()

	if line.has("minigame"):
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
