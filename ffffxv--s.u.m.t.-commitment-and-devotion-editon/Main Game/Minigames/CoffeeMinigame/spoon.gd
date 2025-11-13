extends Area2D
signal stirred

func _ready():
	print("[Spoon] ready for clicks")

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
		print("🥄 Stirred coffee!")
		emit_signal("stirred")
