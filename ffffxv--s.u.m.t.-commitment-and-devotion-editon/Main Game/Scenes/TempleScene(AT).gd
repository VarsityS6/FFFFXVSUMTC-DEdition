extends Node2D

var dialogue = []
var index = 0
var scene_transitioning = false

var preload_portraits = {
	"PlayerTalk.png": preload("res://Portraits/PlayerTalk.png"),
	"NinaSurprised.png": preload("res://Portraits/NinaSurprised.png"),
	"NinaExcited.png": preload("res://Portraits/NinaExcited.png"),
	"JimmyPlaceholder.png": preload("res://Portraits/JimmyPlaceholder.png"),
	"grammy.png": preload ("res://Portraits/grammy.png")
}

@onready var name_label = $NameLabel
@onready var text_label = $TextLabel
@onready var portrait = $Portrait
@onready var choices_container = $Choices
@onready var sfx: AudioStreamPlayer = $"BG Music"

func _ready():
	if sfx.stream:
		sfx.stream.loop = true
		sfx.play()
	dialogue = load_dialogue("res://Dialogue/JIMMYscene3.json")

	if Global.resume_after_minigame:
		Global.resume_after_minigame = false
		get_line_by_id(Global.resume_line_id)
		show_line()
	else:
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
			if scene_transitioning:
				return
			scene_transitioning = true

			if choice.has("scene_change"):
				var target = choice["scene_change"]

				if target == get_tree().current_scene.scene_file_path:
					print("⚠️ Ignoring self-reload request for:", target)
					scene_transitioning = false
					return

				print("Changing to new scene:", target)
				get_tree().change_scene_to_file(target)

			elif choice.has("scene"):
				var scene_id = choice["scene"]
				get_line_by_id(scene_id)
				show_line()
				scene_transitioning = false

			else:
				push_error("Choice missing 'scene' or 'scene_change' key: " + str(choice))
		)

		choices_container.add_child(btn)


func clear_choices():
	for child in choices_container.get_children():
		child.queue_free()

func _input(event):
	if scene_transitioning:
		return
	if event.is_action_pressed("ui_accept"):
		if dialogue.is_empty() or index >= dialogue.size():
			return

		if not dialogue[index].has("choices"):
			index += 1

			while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
				index += 1

			show_line()


func end_dialogue():
	name_label.text = ""
	text_label.text = ""
	portrait.texture = null
	clear_choices()
	print("Dialogue ended")
	get_tree().change_scene_to_file("res://Sandbox/Screenshots.tscn")
