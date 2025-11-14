extends Area2D
signal poured

func _ready():
	# Optional: print debug
	print("[CoffeePot] ready for clicks")

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.pressed:
		print("☕ Coffee poured!")
		emit_signal("poured")
