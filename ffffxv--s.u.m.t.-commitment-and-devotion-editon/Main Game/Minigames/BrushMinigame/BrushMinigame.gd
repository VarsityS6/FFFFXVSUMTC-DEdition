extends Node2D

@onready var comb = $CharraxComb
@onready var hair = $Hair
@onready var word_container = $WordContainer

# --- Hair stage textures ---
var stage1_messy = load("res://Assets/MinigameAssets/BrushMini/Stage1_messy.PNG")
var stage1_clean = load("res://Assets/MinigameAssets/BrushMini/Stage1_clean.PNG")
var stage2_messy = load("res://Assets/MinigameAssets/BrushMini/Stage2_messy.PNG")
var stage2_clean = load("res://Assets/MinigameAssets/BrushMini/Stage2_clean.PNG")
var stage3_messy = load("res://Assets/MinigameAssets/BrushMini/Stage3_messy.PNG")
var stage3_clean = load("res://Assets/MinigameAssets/BrushMini/Stage3_clean.PNG")

# --- Word PNGs ---
var word_textures = [
	load("res://Assets/MinigameAssets/BrushMini/bingbangboom.png"),
	load("res://Assets/MinigameAssets/BrushMini/brushalicious.png"),
	load("res://Assets/MinigameAssets/BrushMini/good.png"),
	load("res://Assets/MinigameAssets/BrushMini/killtastic.png")
]

# --- Points PNG ---
var points_texture = load("res://Assets/MinigameAssets/BrushMini/PointPlaceholder.png")  # ⚠️ update path if needed

# --- Gameplay variables ---
var stage := 1
var is_clean := false
var points := 0
var next_stage_points := 30

# --- Brushing detection ---
var previous_comb_y := 0.0
var brushing_cooldown := 0.0

func _ready():
	randomize()
	_set_hair_texture()
	previous_comb_y = comb.global_position.y
# ----------------------------------------------------
# Handle floating/fading points each frame
# ----------------------------------------------------
func _process(delta):
	# Existing brush logic
	if comb.dragging:
		_check_brushing(delta)
	previous_comb_y = comb.global_position.y

	# Update all floating point sprites
	for sprite in active_point_sprites.duplicate():
		if not is_instance_valid(sprite):
			active_point_sprites.erase(sprite)
			continue
		
		var current_time: float = float(sprite.get_meta("timer")) + delta
		sprite.set_meta("timer", current_time)
		
		var follow_time: float = float(sprite.get_meta("follow_time"))
		var float_time: float = float(sprite.get_meta("float_time"))
		var offset: Vector2 = sprite.get_meta("offset")
		
		if current_time < follow_time and is_instance_valid(comb):
			# Follow comb for a bit
			sprite.global_position = comb.global_position + offset
		elif current_time < follow_time + float_time:
			# Float upward + fade
			var progress: float = (current_time - follow_time) / float_time
			sprite.position.y -= delta * 80.0
			sprite.modulate.a = 1.0 - progress
		else:
			# Lifetime over
			sprite.queue_free()
			active_point_sprites.erase(sprite)


func _check_brushing(delta):
	if brushing_cooldown > 0:
		brushing_cooldown -= delta
		return

	if comb.get_rect().intersects(hair.get_rect()):
		var moving_down = comb.global_position.y > previous_comb_y + 2
		if moving_down:
			points += 1
			brushing_cooldown = 0.05
			
			_spawn_points_follow()
			
			if randi() % 10 == 0:  # higher chance (1 in 10)
				_spawn_word()


			if points >= next_stage_points:
				_advance_stage()

func _advance_stage():
	points = 0
	is_clean = not is_clean

	if is_clean:
		# Show clean hair first
		_set_hair_texture()
		# Wait 2 seconds, then move automatically to next messy stage
		await get_tree().create_timer(1.0).timeout

		stage += 1
		if stage > 3:
			# All stages complete → show win button
			_show_win_button()
			return
		is_clean = false
		_set_hair_texture()
	else:
		# Normal switch from messy → clean
		_set_hair_texture()


func _set_hair_texture():
	match stage:
		1:
			hair.texture = stage1_clean if is_clean else stage1_messy
		2:
			hair.texture = stage2_clean if is_clean else stage2_messy
		3:
			hair.texture = stage3_clean if is_clean else stage3_messy

# --------------------------------------------------------------------
# Floating Words
# --------------------------------------------------------------------
func _spawn_word():
	if word_textures.is_empty():
		return
	
	var texture = word_textures.pick_random()
	var word_sprite = Sprite2D.new()
	word_sprite.texture = texture
	
	word_sprite.global_position = hair.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
	
	var WORD_SCALE = 0.25
	word_sprite.scale = Vector2(WORD_SCALE, WORD_SCALE)
	word_sprite.rotation_degrees = randf_range(-10, 10)
	word_container.add_child(word_sprite)

	var float_distance = randf_range(40, 80)
	var spin_amount = randf_range(-25, 25)
	var float_time = 0.8

	var tween = create_tween()
	tween.tween_property(word_sprite, "scale", Vector2(WORD_SCALE * 1.2, WORD_SCALE * 1.2), 0.15)
	tween.parallel().tween_property(word_sprite, "position:y", word_sprite.position.y - float_distance, float_time)
	tween.parallel().tween_property(word_sprite, "rotation_degrees", word_sprite.rotation_degrees + spin_amount, float_time)
	tween.parallel().tween_property(word_sprite, "modulate:a", 0.0, float_time)
	tween.connect("finished", Callable(word_sprite, "queue_free"))

var active_point_sprites: Array = []  # track active points PNGs

# ----------------------------------------------------
# Spawn floating "Points" PNG that follows comb, then floats up
# ----------------------------------------------------
func _spawn_points_follow():
	if points_texture == null:
		return
	
	var sprite := Sprite2D.new()
	sprite.texture = points_texture
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate = Color(1, 1, 1, 1)
	word_container.add_child(sprite)
	
	# Change these to move where the Points PNG appears
	var x_offset_range := Vector2(-50, 100)   # horizontal random range
	var y_offset := -100                     # base height above comb
	var random_x := randf_range(x_offset_range.x, x_offset_range.y)
	var offset := Vector2(random_x, y_offset)
	
	# Set initial position using offset
	sprite.global_position = comb.global_position + offset
	
	# Store data for later floating/fading
	sprite.set_meta("offset", offset)
	sprite.set_meta("timer", 0.0)
	sprite.set_meta("follow_time", 0.3)
	sprite.set_meta("float_time", 0.6)
	
	active_point_sprites.append(sprite)

func _show_win_button():

	var button := Button.new()
	button.text = "Brushalicious! His hair looks amazing!"
	button.scale = Vector2(2, 2)
	button.position = get_viewport_rect().size / 2 - Vector2(300, 50)
	button.set_anchors_preset(Control.PRESET_CENTER)

	add_child(button)
	button.connect("pressed", Callable(self, "_on_win_button_pressed"))

	# Optional: fade-in effect
	button.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(button, "modulate:a", 1.0, 0.5)

func _on_win_button_pressed():
	Global.resume_after_minigame = true
	Global.resume_line_id = "next_fighters"
	get_tree().change_scene_to_file("res://Main Game/Scenes/FirstScene.tscn")
