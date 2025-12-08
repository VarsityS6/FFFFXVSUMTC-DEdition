extends TextureRect
signal dropped_into_cup(ingredient_name)

var dragging: bool = false
var start_pos: Vector2
var drag_offset: Vector2

func _ready():
	start_pos = global_position
	mouse_filter = Control.MOUSE_FILTER_PASS

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local_mouse = get_local_mouse_position()
				if Rect2(Vector2.ZERO, size).has_point(local_mouse):
					dragging = true
					move_to_front()
					drag_offset = global_position - get_global_mouse_position()
			else:
				if dragging:
					dragging = false
					_check_drop()
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() + drag_offset

func _check_drop():
	var cup = get_tree().get_first_node_in_group("cup")
	if not cup:
		_return_to_start()
		return

	var cup_rect: Rect2 = Rect2()
	if cup is Sprite2D and cup.texture:
		var tex_size = cup.texture.get_size() * cup.scale
		cup_rect = Rect2(cup.global_position - tex_size * 0.5, tex_size)
	else:
		cup_rect = Rect2(cup.global_position, cup.size)

	if cup_rect.has_point(get_global_mouse_position()):
		emit_signal("dropped_into_cup", name)
		call_deferred("_return_to_start")
		return

	_return_to_start()

func _return_to_start():
	global_position = start_pos

func reset_position():
	_return_to_start()
