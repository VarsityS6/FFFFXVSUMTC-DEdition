extends Node2D

var dialogue = []
var index = 0

var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"PlayerSurprise.png": preload("res://portraits/PlayerSurprise.png"),
	"PlayerTriumphant.png": preload("res://portraits/PlayerTriumphant.png"),
	"JimmyPlaceholder.png": preload("res://portraits/JimmyPlaceholder.png")
}

@onready var name_label = $NameLabel
@onready var text_label = $TextLabel
@onready var portrait = $Portrait
@onready var choices_container = $Choices

func _ready():
	print("TempleScene loaded successfully!")
	print("Root node:", get_name())

	dialogue = load_dialogue("res://Dialogue/JIMMYscene2.json")
	if dialogue.size() == 0:
		push_error("⚠️ Dialogue file empty or not found!")
	else:
		print("Loaded dialogue lines:", dialogue.size())

	show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open dialogue file: " + path)
		return []
	var content = file.get_as_text()
	var result = JSON.parse_string(content)
	if result == null:
		push_error("Failed to parse JSON from: " + path)
		return []
	return result

func get_line_by_id(line_id: String) -> Dictionary:
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

	if line.has("type") and line["type"] == "comment":
		index += 1
		show_line()
		return

	# Safely set speaker + text
	if name_label:
		name_label.text = line.get("speaker", "")
	else:
		print("⚠️ NameLabel not found!")

	if text_label:
		text_label.text = line.get("text", "")
	else:
		print("⚠️ TextLabel not found!")

	# Portrait handling
	if portrait:
		if line.has("portrait") and line["portrait"] != "":
			portrait.texture = preload_portraits.get(line["portrait"], null)
		else:
			portrait.texture = null
	else:
		print("⚠️ Portrait node not found!")

	# Handle choices
	if line.has("choices"):
		show_choices(line["choices"])
	else:
		clear_choices()

func show_choices(choices: Array):
	clear_choices()
	if not choices_container:
		print("⚠️ Choices container not found!")
		return

	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "???")
		var scene_id = choice.get("scene", "")
		btn.pressed.connect(func():
			get_line_by_id(scene_id)
			show_line()
		)
		choices_container.add_child(btn)

func clear_choices():
	if not choices_container:
		return
	for child in choices_container.get_children():
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
