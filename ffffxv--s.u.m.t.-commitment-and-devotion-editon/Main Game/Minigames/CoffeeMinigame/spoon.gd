extends TextureRect

signal dropped_into_cup(ingredient_name)

var dragging := false
var start_pos: Vector2
var drag_offset: Vector2


func _ready():
	start_pos = global_position
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event):

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:
			dragging = true
			move_to_front()

			# Prevent snapping
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
		print("[Ingredient] ❌ No cup in group 'cup'")
		_return_to_start()
		return

	# Build cup hitbox manually using texture
	var cup_size = Vector2.ZERO

	if cup is Sprite2D and cup.texture:
		cup_size = cup.texture.get_size() * cup.scale
	else:
		print("[Ingredient] Invalid cup type or no texture")
		_return_to_start()
		return

	var cup_rect = Rect2(
		cup.global_position - (cup_size / 2),
		cup_size
	)

	if cup_rect.has_point(get_global_mouse_position()):
		print("[Ingredient] ✅ Dropped into cup:", name)

		emit_signal("dropped_into_cup", name)

		# Visually snap above the cup
		global_position = cup.global_position + Vector2(0, -20)
	else:
		print("[Ingredient] ❌ Missed cup:", name)
		_return_to_start()


func _return_to_start():
	global_position = start_pos


func reset_position():
	_return_to_start()
