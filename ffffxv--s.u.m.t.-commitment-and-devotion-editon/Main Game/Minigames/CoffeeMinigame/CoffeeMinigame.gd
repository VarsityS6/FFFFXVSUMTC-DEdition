extends Node2D

@onready var cup: Sprite2D = $Cup
@onready var coffee_pot = $CoffeePot
@onready var spoon = $Spoon
@onready var timer: Timer = $Timer

# Use exact node names (recommend no spaces). If your node names are different, update these.
var correct_order: Array = [
	"CoconutMilk",
	"CaramelSyrup",
	"Nutmeg",
	"GrandulatedSugar",
	"CoffeePot",
	"Spoon"
]

var added_ingredients: Array = []
var time_limit: float = 20.0

func _ready():
	print("[Minigame] ready. Time limit:", time_limit, "seconds.")
	timer.wait_time = time_limit
	# Connect timer safely
	if not timer.is_connected("timeout", Callable(self, "_on_time_out")):
		timer.timeout.connect(_on_time_out)
	timer.start()

	# Connect CoffeePot and Spoon signals if they exist (they should emit 'poured' and 'stirred')
	if coffee_pot and coffee_pot.has_signal("poured"):
		coffee_pot.poured.connect(_on_coffee_poured)
		print("[Minigame] connected coffee_pot.poured")
	else:
		print("[Minigame] coffee_pot missing 'poured' signal or node not found")

	if spoon and spoon.has_signal("stirred"):
		spoon.stirred.connect(_on_spoon_stirred)
		print("[Minigame] connected spoon.stirred")
	else:
		print("[Minigame] spoon missing 'stirred' signal or node not found")

	# Connect all ingredients by group 'ingredient'
	var ingredients = get_tree().get_nodes_in_group("ingredient")
	if ingredients.size() == 0:
		print("[Minigame] WARNING: No nodes found in group 'ingredient'. Falling back to Ingredients child.")
		# fallback: try children under a node called "Ingredients"
		if has_node("Ingredients"):
			ingredients = $Ingredients.get_children()
			print("[Minigame] found", ingredients.size(), "children under Ingredients")
		else:
			print("[Minigame] No Ingredients node either -- nothing to connect!")
	for ing in ingredients:
		if ing and ing.has_signal("dropped_into_cup"):
			ing.dropped_into_cup.connect(_on_ingredient_dropped)
			print("[Minigame] connected ingredient signal for:", ing.name)
		else:
			print("[Minigame] Ingredient node missing signal 'dropped_into_cup':", ing)

	# Ensure cup is in group "cup" (debug)
	if not cup:
		print("[Minigame] ERROR: Cup node not found at $Cup")
	else:
		var in_group = cup.is_in_group("cup")
		print("[Minigame] Cup found:", cup.name, "in group 'cup'? ", in_group)

	print("[Minigame] setup complete.")

# --- signal handlers and logic ---
func _on_ingredient_dropped(ingredient_name: String) -> void:
	print("[Minigame] received dropped ingredient:", ingredient_name)
	added_ingredients.append(ingredient_name)
	_check_recipe_progress()

func _on_coffee_poured() -> void:
	print("[Minigame] received poured signal")
	added_ingredients.append("CoffeePot")
	_check_recipe_progress()

func _on_spoon_stirred() -> void:
	print("[Minigame] received stirred signal")
	added_ingredients.append("Spoon")
	_check_recipe_progress()

func _check_recipe_progress() -> void:
	var idx = added_ingredients.size() - 1
	# Safety: if idx is out of range for correct_order, finish (overfill)
	if idx >= correct_order.size():
		print("[Minigame] too many steps; finishing attempt.")
		_finish_attempt()
		return

	# Validate latest step
	var expected = correct_order[idx]
	var actual = added_ingredients[idx]
	print("[Minigame] step", idx, "expected:", expected, "actual:", actual)
	if actual != expected:
		print("[Minigame] ❌ Wrong ingredient at step", idx, "expected:", expected, "got:", actual, " -> resetting")
		_reset_attempt()
		return

	# If fully matched
	if added_ingredients == correct_order:
		_successful_coffee()

func _reset_attempt() -> void:
	print("[Minigame] 🔁 Resetting cup and ingredients.")
	added_ingredients.clear()
	timer.start()
	# reset ingredient positions
	var ingredients = get_tree().get_nodes_in_group("ingredient")
	for ing in ingredients:
		if ing and ing.has_method("reset_position"):
			ing.reset_position()
	# reset cup texture if you use a reset image
	if cup and cup.texture:
		# adjust the path to your empty cup asset if needed
		var empty_path = "res://Assets/MinigameAssets/CoffeeMini/EmptyMug.png"
		if cup.texture.resource_path != empty_path:
			if ResourceLoader.exists(empty_path):
				cup.texture = load(empty_path)
			else:
				print("[Minigame] WARNING: empty cup texture not found at", empty_path)
	print("[Minigame] printed: Cup reset")

func _on_time_out() -> void:
	print("[Minigame] ⏰ Time's up! Resetting.")
	_reset_attempt()

func _successful_coffee() -> void:
	timer.stop()
	print("[Minigame] ✅ Coffee completed successfully!")
	var full_path = "res://Assets/MinigameAssets/CoffeeMini/CoffeeFull.png"
	if ResourceLoader.exists(full_path):
		cup.texture = load(full_path)
	else:
		print("[Minigame] WARNING: full cup texture not found at", full_path)
	var b := Button.new()
	b.text = "🎉 Congratulations!"
	var vp_size = get_viewport_rect().size
	b.position = vp_size / 2 - b.get_minimum_size() / 2
	add_child(b)
	b.pressed.connect(_on_congrats_pressed)
	print("[Minigame] Congratulations button created.")

func _finish_attempt() -> void:
	if added_ingredients == correct_order:
		_successful_coffee()
	else:
		_reset_attempt()

func _on_congrats_pressed() -> void:
	Global.resume_after_minigame = true 
	Global.resume_line_id = "taztransition"
	get_tree().change_scene_to_file("res://Main Game/Scenes/AcidLakeScene(PJ).tscn")
	print("[Minigame] 🎊 Minigame complete! Emitting minigame_complete signal.")
