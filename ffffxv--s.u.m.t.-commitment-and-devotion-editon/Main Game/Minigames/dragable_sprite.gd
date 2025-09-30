extends Node

var is_dragable = false # state management
var mouse_offset # center mouse on click

func _physics_process(delta):
	pass
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_rect().has_point(to_local(event.positon)):
				print("Clicked on sprite")
		else:
			print("up")
