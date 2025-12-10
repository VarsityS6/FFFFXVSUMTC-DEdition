extends Node2D

const DIALOGUE_RES = preload("res://Dialogue/CHARRAXscene1.tres")

var dialogue: Array = []
var index: int = 0
var resume_line_id: String = ""

var preload_portraits = {
	"PlayerTalk.png": preload("res://portraits/PlayerTalk.png"),
	"NinaSurprise.png": preload("res://portraits/NinaSurprised.png"),
	"NinaExcited.png": preload("res://portraits/NinaExcited.png"),
	"NinaWorried.png": preload("res://portraits/NinaWorried.png"),
	"CConfused.png": preload("res://portraits/CConfused.png"),
	"Charrax01.png": preload("res://portraits/Charrax01.png"),
	"CHair.png": preload("res://portraits/CHair.png")
}

@onready var sfx: AudioStreamPlayer = $"BG Music"

func _ready() -> void:
	# Start BG music
	if sfx.stream:
		sfx.stream.loop = true
		sfx.play()

	# Load dialogue from preloaded .tres
	dialogue = load_dialogue_from_tres()

	# If something went wrong and dialogue is empty, don't crash
	if dialogue.is_empty():
		push_error("Dialogue array is empty in FirstScene.gd")
		return

	if Global.resume_after_minigame:
		Global.resume_after_minigame = false
		get_line_by_id(Global.resume_line_id)
		show_line()
	else:
		show_line()

func load_dialogue_from_tres() -> Array:
	if DIALOGUE_RES == null:
		push_error("DIALOGUE_RES is null. Check path: res://Dialogue/CHARRAXscene1.tres")
		return []

	# DIALOGUE_RES is your DialogueResource with a 'text' property
	var text := DIALOGUE_RES.text
	if typeof(text) != TYPE_STRING or text.is_empty():
		push_error("Dialogue resource has no valid text")
		return []

	var parsed = JSON.parse_string(text)

	# In Godot 4, parse_string returns the parsed value directly (Array/Dictionary) or null on error
	if parsed == null:
		push_error("JSON.parse_string failed for CHARRAXscene1.tres")
		return []

	if typeof(parsed) != TYPE_ARRAY:
		push_error("Parsed dialogue is not an Array")
		return []

	return parsed

func get_line_by_id(line_id: String) -> Dictionary:
	if line_id == "hair_minigame":
		get_tree().change_scene_to_file("res://Main Game/Minigames/BrushMinigame/BrushMinigame.tscn")
		return {}

	for i in range(dialogue.size()):
		if dialogue[i].has("id") and dialogue[i]["id"] == line_id:
			index = i
			return dialogue[i]

	return {}

func show_line() -> void:
	# Safety: don't do anything if dialogue is empty
	if dialogue.is_empty():
		push_error("show_line() called with empty dialogue")
		return

	while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
		index += 1

	if index >= dialogue.size():
		end_dialogue()
		return

	var line: Dictionary = dialogue[index]

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
		resume_line_id = line.get("resume_id", "")
		Global.resume_line_id = resume_line_id
		get_tree().change_scene_to_file(line["minigame"])

func show_choices(choices: Array) -> void:
	clear_choices()
	for choice in choices:
		var btn := Button.new()
		btn.text = choice["text"]
		btn.pressed.connect(func() -> void:
			if choice.has("scene_change"):
				get_tree().change_scene_to_file(choice["scene_change"])
			else:
				var scene_id: String = choice["scene"]
				get_line_by_id(scene_id)
				show_line()
		)
		$Choices.add_child(btn)

func clear_choices() -> void:
	for child in $Choices.get_children():
		child.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Safety: don't touch dialogue if it's empty
		if dialogue.is_empty():
			return

		Global.stop_sfx()

		if index >= dialogue.size():
			return

		if not dialogue[index].has("choices"):
			index += 1
			while index < dialogue.size() and dialogue[index].get("type", "") == "comment":
				index += 1
			show_line()

func end_dialogue() -> void:
	Global.stop_sfx()
	$NameLabel.text = ""
	$TextLabel.text = ""
	$Portrait.texture = null
	clear_choices()
	print("Dialogue ended")
	get_tree().change_scene_to_file("res://Sandbox/Screenshots.tscn")
