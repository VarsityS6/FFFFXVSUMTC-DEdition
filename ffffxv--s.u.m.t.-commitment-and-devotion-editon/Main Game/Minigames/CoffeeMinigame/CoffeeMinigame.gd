extends Node2D

# The correct recipe order
const CORRECT_ORDER = [
	"CoconutMilk",
	"CaramelSyrup",
	"Nutmeg",
	"GranulatedSugar",
	"CoffeePot", # after all ingredients
	"Spoon"      # stir at the end
]

# State tracking
var added_ingredients: Array[String] = []
var time_limit := 15.0

@onready var cup = $Cup
@onready var timer = $Timer
@onready var note_label = $Note/NoteLabel

func _ready():
	timer.wait_time = time_limit
	timer.start()
	
	# Display the recipe on the note
	note_label.text = "Recipe:\n1. Coconut Milk\n2. Caramel Syrup\n3. Nutmeg\n4. Granulated Sugar\n5. Pour Coffee\n6. Stir"
	
	timer.timeout.connect(_on_time_up)
	
	# Connect all ingredient drop signals
	for ingredient in $Ingredients.get_children():
		ingredient.connect("dropped_into_cup", _on_ingredient_dropped)
	
	$CoffeePot.connect("poured", _on_ingredient_dropped.bind("CoffeePot"))
	$Spoon.connect("stirred", _on_ingredient_dropped.bind("Spoon"))


func _on_ingredient_dropped(name: String):
	added_ingredients.append(name)
	
	if added_ingredients.size() == CORRECT_ORDER.size():
		if added_ingredients == CORRECT_ORDER:
			_on_success()
		else:
			_on_fail()


func _on_time_up():
	_on_fail()


func _on_fail():
	timer.stop()
	print("❌ Wrong order or time up! Resetting...")
	reset_game()


func _on_success():
	timer.stop()
	print("✅ Coffee made correctly!")
	emit_signal("minigame_completed") # optional for main game


func reset_game():
	added_ingredients.clear()
	timer.start()
	print("New attempt started.")
	
	# Reset the cup (you can replace this with an animation if you want)
	if cup:
		cup.modulate = Color.WHITE  # visually reset (if you were tinting/filling it)
	
	# Optionally reset ingredient positions if you want them to return to original spots
	for ingredient in $Ingredients.get_children():
		if ingredient.has_method("reset_position"):
			ingredient.reset_position()
