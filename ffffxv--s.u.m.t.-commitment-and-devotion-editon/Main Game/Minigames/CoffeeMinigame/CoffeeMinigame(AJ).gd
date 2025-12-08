extends Node2D

@onready var cup: Sprite2D = $Cup
@onready var coffee_pot: TextureRect = $Ingredients/CoffeePot
@onready var spoon: TextureRect = $Ingredients/Spoon

@onready var label_coconut: Label = $IngredientList/CoconutMilkLabel
@onready var label_caramel: Label = $IngredientList/CaramelSyrupLabel
@onready var label_nutmeg: Label = $IngredientList/NutmegLabel
@onready var label_sugar: Label = $IngredientList/GrandulatedSugarLabel
@onready var label_pour: Label = $IngredientList/CoffeePotLabel
@onready var label_stir: Label = $IngredientList/SpoonLabel

var correct_order: Array = [
	"CoconutMilk",
	"CaramelSyrup",
	"Nutmeg",
	"GrandulatedSugar",
	"CoffeePot",
	"Spoon"
]

var added_ingredients: Array = []
var try_again_popup: Sprite2D
var struck_lines := {}

func _ready():
	var ingredients = get_tree().get_nodes_in_group("ingredient")
	for ing in ingredients:
		if ing and ing.has_signal("dropped_into_cup"):
			ing.dropped_into_cup.connect(_on_ingredient_dropped)
	_reset_labels()

func _on_ingredient_dropped(ingredient_name: String):
	added_ingredients.append(ingredient_name)
	var step = added_ingredients.size() - 1
	if step < 0:
		return
	if step >= correct_order.size():
		_reset_attempt()
		return
	if ingredient_name != correct_order[step]:
		_reset_attempt()
		return
	_mark_label_as_done(ingredient_name)
	_check_popups()
	if added_ingredients == correct_order:
		_successful_coffee()

func _mark_label_as_done(ingredient_name: String):
	var map = {
		"CoconutMilk": label_coconut,
		"CaramelSyrup": label_caramel,
		"Nutmeg": label_nutmeg,
		"GrandulatedSugar": label_sugar,
		"CoffeePot": label_pour,
		"Spoon": label_stir
	}
	if not map.has(ingredient_name):
		return

	var lbl: Label = map[ingredient_name]
	lbl.modulate = Color(0.443, 0.443, 0.443, 1.0)

	if struck_lines.has(ingredient_name):
		return

	var font = lbl.get_theme_font("font")
	var font_size = lbl.get_theme_font_size("font_size")
	var text_width = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_height = font.get_height(font_size)

	var line := ColorRect.new()
	line.color = Color(1, 0, 0)
	line.size = Vector2(text_width, 3)
	line.position = Vector2(0, text_height * 0.5 - 1)

	lbl.add_child(line)
	struck_lines[ingredient_name] = line

func _reset_labels():
	struck_lines.clear()

	for lbl in [label_coconut, label_caramel, label_nutmeg, label_sugar, label_pour, label_stir]:
		lbl.modulate = Color(0.0, 0.0, 0.0, 1.0)
		for child in lbl.get_children():
			if child is ColorRect:
				child.queue_free()

func _check_popups():
	var idx = added_ingredients.size()
	if idx == 1:
		_show_floating_popup("res://Assets/MinigameAssets/CoffeeMini/mmmm coffee.png")
	elif idx == 3:
		_show_floating_popup("res://Assets/MinigameAssets/CoffeeMini/coffeelicious.png")
	elif idx == 5:
		_show_floating_popup("res://Assets/MinigameAssets/CoffeeMini/tastin_yummy.png")

func _show_floating_popup(path: String):
	if not ResourceLoader.exists(path):
		return
	var popup := Sprite2D.new()
	popup.texture = load(path)
	popup.position = get_viewport_rect().size / 2
	popup.scale = Vector2(0.8,0.8)
	popup.z_index = 50
	add_child(popup)
	var tween = get_tree().create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 120, 2.0)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 2.0)
	await tween.finished
	popup.queue_free()

func _reset_attempt():
	added_ingredients.clear()
	var ingredients = get_tree().get_nodes_in_group("ingredient")
	for ing in ingredients:
		if ing and ing.has_method("reset_position"):
			ing.reset_position()
	var empty_path = "res://Assets/MinigameAssets/CoffeeMini/EmptyMug.png"
	if ResourceLoader.exists(empty_path):
		cup.texture = load(empty_path)
	_reset_labels()
	_show_try_again()

func _show_try_again():
	if try_again_popup and try_again_popup.is_inside_tree():
		try_again_popup.queue_free()
	var path = "res://Assets/MinigameAssets/CoffeeMini/try again.png"
	if not ResourceLoader.exists(path):
		return
	try_again_popup = Sprite2D.new()
	try_again_popup.texture = load(path)
	try_again_popup.z_index = 100
	try_again_popup.position = get_viewport_rect().size / 2
	add_child(try_again_popup)
	var tween = get_tree().create_tween()
	tween.tween_property(try_again_popup, "modulate:a", 0.0, 2.0)
	await tween.finished
	if try_again_popup:
		try_again_popup.queue_free()

func _successful_coffee():
	var full_path = "res://Assets/MinigameAssets/CoffeeMini/CoffeeFull.png"
	if ResourceLoader.exists(full_path):
		cup.texture = load(full_path)

	var b := Button.new()
	b.text = "Taz found this coffee acceptable"
	b.scale = Vector2(1.5, 1.5)
	add_child(b)
	await get_tree().process_frame
	var vp = get_viewport_rect().size
	var bs = b.size
	b.position = vp / 2 - bs / 2 + Vector2(-50, 0)
	b.pressed.connect(_on_congrats_pressed)

func _on_congrats_pressed():
	Global.resume_after_minigame = true
	Global.resume_line_id = "taztransition"
	get_tree().change_scene_to_file("res://Main Game/Scenes/AcidLakeScene(AJ).tscn")
