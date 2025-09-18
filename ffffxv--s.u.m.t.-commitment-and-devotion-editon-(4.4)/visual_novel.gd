extends Node2D

var dialogue = []
var index = 0

func _ready():
	dialogue = load_dialogue("res://Dialogue.json")
	show_line()

func load_dialogue(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func show_line():
	if index >= dialogue.size():
		$TextLabel.text = "[End of dialogue]"
		$Portrait.texture = null
		return
	
	var line = dialogue[index]

	$NameLabel.text = line.get("speaker", "")
	$TextLabel.text = line["text"]

	if line.has("portrait") and line["portrait"] != "":
		var path = "res://portraits/" + line["portrait"]
		if ResourceLoader.exists(path):
			$Portrait.texture = load(path)
		else:
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
