extends TextureRect
signal dropped_into_cup(ingredient_name)

var dragging: bool = false
var start_pos: Vector2
var drag_offset: Vector2

func _ready():
	start_pos = global_position
	# Ensure it can receive mouse events
	mouse_filter = Control.MOUSE_FILTER_PASS
	print("[Ingredient] ready:", name, "start_pos:", start_pos)

func _gui_input(event):
	# debug every event type (remove or comment out later)
	# print("[Ingredient] _gui_input", name, typeof(event), event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_mouse = get_local_mouse_position()
				if Rect2(Vector2.ZERO, size).has_point(local_mouse):
					dragging = true
					move_to_front()
					drag_offset = global_position - get_global_mouse_position()
					print("[Ingredient] begin drag:", name, "offset:", drag_offset)
			else:
				if dragging:
					dragging = false
					print("[Ingredient] end drag:", name, "mouse_pos:", get_global_mouse_position())
					_check_drop()
	elif event is InputEventMouseMotion and dragging:
		# follow mouse in world coords (works with Node2D root)
		global_position = get_global_mouse_position() + drag_offset

func _check_drop():
	var cup = get_tree().get_first_node_in_group("cup")
	if not cup:
		print("[Ingredient] No cup found in group 'cup'!")
		_return_to_start()
		return

	# If cup is a Sprite2D, form its rect in global coords
	if cup is Sprite2D and cup.texture:
		var cup_size = cup.texture.get_size() * cup.scale
		var cup_rect = Rect2(cup.global_position - (cup_size / 2.0), cup_size)
		print("[Ingredient] checking cup rect:", cup_rect, "mouse:", get_global_mouse_position())
		if cup_rect.has_point(get_global_mouse_position()):
			print("[Ingredient] DROPPED into cup:", name)
			emit_signal("dropped_into_cup", name)  # emit node name
			# optional: snap into cup
			global_position = cup.global_position + Vector2(0, -20)
			return

	# Not dropped on cup
	print("[Ingredient] not dropped on cup, returning:", name)
	_return_to_start()

func _return_to_start():
	global_position = start_pos

func reset_position():
	_return_to_start()
