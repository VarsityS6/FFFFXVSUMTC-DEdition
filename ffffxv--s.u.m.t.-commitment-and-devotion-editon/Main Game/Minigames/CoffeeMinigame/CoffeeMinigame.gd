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
@onready var slash_anim = $SlashAnimation

func _ready():
	timer.wait_time = time_limit
	timer.start()
	
	# Display recipe on the note
	note_label.text = "Recipe:\n1. Coconut Milk\n2. Caramel Syrup\n3. Nutmeg\n4. Granulated Sugar\n5. Pour Coffee\n6. Stir"
	
	# Connect timer timeout
	timer.timeout.connect(_on_time_up)
	
	# Make ingredients draggable
	for ingredient in $Ingredients.get_children():
		ingredient.connect("dropped_into_cup", _on_ingredient_dropped)
	
	$CoffeePot.connect("poured", _on_ingredient_dropped.bind("CoffeePot"))
	$Spoon.connect("stirred", _on_ingredient_dropped.bind("Spoon"))


func _on_ingredient_dropped(name: String):
	added_ingredients.append(name)
	
	# Check progress
	if added_ingredients.size() == CORRECT_ORDER.size():
		if added_ingredients == CORRECT_ORDER:
			_on_success()
		else:
			_on_fail()


func _on_time_up():
	_on_fail()


func _on_fail():
	timer.stop()
	slash_anim.play("slash")  # your animation to destroy the cup
	await slash_anim.animation_finished
	reset_game()


func _on_success():
	timer.stop()
	print("✅ Coffee made correctly!")
	emit_signal("minigame_completed") # optional for main game
	# You could also play a success animation or sound


func reset_game():
	added_ingredients.clear()
	timer.start()
	print("Resetting for new attempt")
	# Replace cup with a new one (instantiate or reset texture)
	# Optionally reset ingredient positions
