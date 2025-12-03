extends Node2D

@onready var cup: Sprite2D = $Cup
@onready var coffee_pot: Sprite2D = $CoffeePot
@onready var spoon: Sprite2D = $Spoon

# Use EXACT node names
var correct_order: Array = [
	"CoconutMilk",
	"CaramelSyrup",
	"Nutmeg",
	"GrandulatedSugar",
	"CoffeePot",
	"Spoon"
]

var added_ingredients: Array = []

# Optional Try Again popup node
var try_again_popup: Sprite2D


func _ready():
	print("[Minigame] ready. Timer removed.")

	# Connect all draggable elements (including pot + spoon)
	var ingredients = get_tree().get_nodes_in_group("ingredient")

	if ingredients.size() == 0:
		print("[Minigame] ❌ No nodes found in group 'ingredient'")
	else:
		print("[Minigame]", ingredients.size(), "ingredients found")

	for ing in ingredients:
		if ing and ing.has_signal("dropped_into_cup"):
			ing.dropped_into_cup.connect(_on_ingredient_dropped)
			print("[Minigame] connected:", ing.name)
		else:
			print("[Minigame] ⚠️ Missing signal on:", ing.name)

	# Check cup group
	if not cup:
		print("[Minigame] ERROR: Cup node not found")
	else:
		print("[Minigame] Cup:", cup.name, "in group?", cup.is_in_group("cup"))

	print("[Minigame] setup complete.")


func _on_ingredient_dropped(ingredient_name: String):
	print("[Minigame] dropped:", ingredient_name)
	added_ingredients.append(ingredient_name)
	_check_recipe_progress()


func _check_recipe_progress():

	var idx = added_ingredients.size() - 1

	if idx >= correct_order.size():
		print("[Minigame] Too many items → reset")
		_reset_attempt()
		return

	var expected = correct_order[idx]
	var actual = added_ingredients[idx]

	print("[Minigame] step", idx, "| expected:", expected, "| actual:", actual)

	if actual != expected:
		print("[Minigame] ❌ Wrong ingredient. Resetting.")
		_reset_attempt()
		return

	if added_ingredients == correct_order:
		_successful_coffee()


func _reset_attempt():
	print("[Minigame] 🔁 Resetting cup & ingredients")
	added_ingredients.clear()

	# Reset all ingredient positions
	var ingredients = get_tree().get_nodes_in_group("ingredient")
	for ing in ingredients:
		if ing.has_method("reset_position"):
			ing.reset_position()

	# Reset cup texture
	var empty_path = "res://Assets/MinigameAssets/CoffeeMini/EmptyMug.png"
	if ResourceLoader.exists(empty_path):
		cup.texture = load(empty_path)

	_show_try_again()

	print("[Minigame] Printed: Try again!")


func _show_try_again():
	# Remove old popup if one exists
	if try_again_popup and try_again_popup.is_inside_tree():
		try_again_popup.queue_free()

	var path = "res://Assets/MinigameAssets/BrushMini/harder.png"

	if not ResourceLoader.exists(path):
		print("[Minigame] ❌ Tryagain.png not found:", path)
		return

	try_again_popup = Sprite2D.new()
	try_again_popup.texture = load(path)
	try_again_popup.z_index = 100
	try_again_popup.position = get_viewport_rect().size / 2
	add_child(try_again_popup)

	# Auto-remove after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if try_again_popup:
		try_again_popup.queue_free()


func _successful_coffee():
	print("[Minigame] ✅ Coffee completed successfully!")

	var full_path = "res://Assets/MinigameAssets/CoffeeMini/CoffeeFull.png"
	if ResourceLoader.exists(full_path):
		cup.texture = load(full_path)

	var b := Button.new()
	b.text = "🎉 Congratulations!"
	var vp_size = get_viewport_rect().size
	b.position = vp_size / 2 - b.get_minimum_size() / 2
	b.scale = Vector2(1.5, 1.5)
	add_child(b)

	b.pressed.connect(_on_congrats_pressed)

	print("[Minigame] Congratulations button created.")


func _on_congrats_pressed():
	Global.resume_after_minigame = true
	Global.resume_line_id = "taztransition"
	get_tree().change_scene_to_file("res://Main Game/Scenes/AcidLakeScene(AJ).tscn")
	print("[Minigame] 🎊 Minigame complete!")
