extends Node2D

func _ready():
	$Restart.pressed.connect(_on_Restart_pressed)

func _on_Restart_pressed():
	get_tree().change_scene_to_file("res://Main_Menu.tscn")
