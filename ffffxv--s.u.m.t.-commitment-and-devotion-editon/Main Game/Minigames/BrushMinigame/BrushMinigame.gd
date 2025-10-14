extends Node2D

@onready var comb = $CharraxComb
@onready var hair = $Hair
@onready var word_container = $WordContainer

# --- Hair stage textures ---
var stage1_messy = load("res://Main Game/Minigames/BrushMinigame/Stage1_messy.PNG")
var stage1_clean = load("res://Main Game/Minigames/BrushMinigame/Stage1_clean.PNG")
var stage2_messy = load("res://Main Game/Minigames/BrushMinigame/Stage2_messy.PNG")
var stage2_clean = load("res://Main Game/Minigames/BrushMinigame/Stage2_clean.PNG")
var stage3_messy = load("res://Main Game/Minigames/BrushMinigame/Stage3_messy.PNG")
var stage3_clean = load("res://Main Game/Minigames/BrushMinigame/Stage3_clean.PNG")

# --- Word PNGs ---
var word_textures = [
	load("res://Assets/MinigameAssets/BrushMini/bingbangboom.png"),
	load("res://Assets/MinigameAssets/BrushMini/brushalicious.png"),
	load("res://Assets/MinigameAssets/BrushMini/good.png"),
	load("res://Assets/MinigameAssets/BrushMini/killtastic.png")
]

# --- Gameplay variables ---
var stage := 1
var is_clean := false
var points := 0
var next_stage_points := 100  # how much brushing needed per stage

func _ready():
	randomize()
	_set_hair_texture()

func _process(_delta):
	if comb.dragging:
		_check_brushing()

func _check_brushing():
	# Simple overlap detection between comb and hair
	if comb.get_rect().intersects(hair.get_rect()):
		points += 1

		# Occasionally spawn a word
		if randi() % 50 == 0:
			_spawn_word()

		# Move to next stage if enough brushing done
		if points >= next_stage_points:
			_advance_stage()

func _advance_stage():
	points = 0
	is_clean = not is_clean
	
	if is_clean:
		_set_hair_texture()
	else:
		stage += 1
		if stage > 3:
			stage = 1  # loop back or trigger win
		_set_hair_texture()

func _set_hair_texture():
	match stage:
		1:
			hair.texture = stage1_clean if is_clean else stage1_messy
		2:
			hair.texture = stage2_clean if is_clean else stage2_messy
		3:
			hair.texture = stage3_clean if is_clean else stage3_messy

func _spawn_word():
	if word_textures.is_empty():
		return
	
	var texture = word_textures.pick_random()
	var word_sprite = Sprite2D.new()
	word_sprite.texture = texture
	
	# Random offset near hair
	word_sprite.global_position = hair.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	word_sprite.scale = Vector2(0.6, 0.6)
	word_container.add_child(word_sprite)

	# Animate the word (pop up + fade)
	var tween = create_tween()
	tween.tween_property(word_sprite, "scale", Vector2(0.25, 0.25), 0.2)
	tween.tween_property(word_sprite, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.connect("finished", func(): word_sprite.queue_free())
