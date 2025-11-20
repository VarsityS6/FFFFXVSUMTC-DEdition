extends Node2D

@onready var comb = $CharraxComb
@onready var hair = $Hair
@onready var word_container = $WordContainer

# --- Progress Bar + UI ---
@onready var progress_bar = $CanvasLayer/UI/ProgressBar
@onready var charrax_face = $CanvasLayer/UI/CharraxFace

var face_neutral = load("res://Assets/MinigameAssets/BrushMini/CharraxRighMessy.png")
var face_happy = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")
var face_amazed = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")

# --- Hair stage textures ---
var stage1_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxLeftMessy.png")
var stage1_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxLeftNeat.png")
var stage2_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxBackMessy.png")
var stage2_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxBackNeat.png")
var stage3_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxRighMessy.png")
var stage3_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")

# --- Word PNGs ---
var word_textures = [
	load("res://Assets/MinigameAssets/BrushMini/bingbangboom.png"),
	load("res://Assets/MinigameAssets/BrushMini/brushalicious.png"),
	load("res://Assets/MinigameAssets/BrushMini/good.png"),
	load("res://Assets/MinigameAssets/BrushMini/killtastic.png"),
	load("res://Assets/MinigameAssets/BrushMini/encouragement.png"),
	load("res://Assets/MinigameAssets/BrushMini/Fatabulous.png"),
	load("res://Assets/MinigameAssets/BrushMini/flawless.png"),
	load("res://Assets/MinigameAssets/BrushMini/harder.png"),
	load("res://Assets/MinigameAssets/BrushMini/krakakoom.png"),
	load("res://Assets/MinigameAssets/BrushMini/rock-and-roll.png"),
	load("res://Assets/MinigameAssets/BrushMini/stupendous.png"),
	load("res://Assets/MinigameAssets/BrushMini/super-cool-dude.png"),
	load("res://Assets/MinigameAssets/BrushMini/yeah-baby-keep-going.png"),
]

# --- Points PNG ---
var points_texture = load("res://Assets/MinigameAssets/BrushMini/PointPlaceholder.png")

# --- Gameplay variables ---
var stage := 1
var is_clean := false
var points := 0
var next_stage_points := 30

# --- Brushing detection ---
var previous_comb_y := 0.0
var brushing_cooldown := 0.0

# Track active sprites
var active_point_sprites: Array = []


func _ready():
	randomize()
	_set_hair_texture()
	previous_comb_y = comb.global_position.y

	# Initialize UI
	progress_bar.max_value = next_stage_points
	progress_bar.value = 0
	progress_bar.min_value = 0
	charrax_face.texture = face_neutral
	_update_progress_bar()


func _process(delta):
	# Brushing logic
	if comb.dragging:
		_check_brushing(delta)
	previous_comb_y = comb.global_position.y

	# Update floating points
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
			sprite.global_position = comb.global_position + offset
		elif current_time < follow_time + float_time:
			var progress: float = (current_time - follow_time) / float_time
			sprite.position.y -= delta * 80.0
			sprite.modulate.a = 1.0 - progress
		else:
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

			# Update UI
			progress_bar.value = points
			_update_charrax_face()
			_update_progress_bar()

			# Meaningful word spawning
			var ratio = float(points) / next_stage_points

			if ratio < 0.3 and points % 8 == 0:
				_spawn_word()
			elif ratio < 0.7 and points % 6 == 0:
				_spawn_word()
			else:
				if points % 4 == 0:
					_spawn_word()

			if points >= next_stage_points:
				_advance_stage()


func _advance_stage():
	points = 0
	progress_bar.value = 0
	charrax_face.texture = face_neutral
	_update_progress_bar()

	is_clean = not is_clean

	if is_clean:
		_set_hair_texture()
		await get_tree().create_timer(1.0).timeout

		stage += 1

		if stage > 3:
			_show_win_button()
			return

		is_clean = false
		_set_hair_texture()
	else:
		_set_hair_texture()


func _set_hair_texture():
	match stage:
		1:
			hair.texture = stage1_clean if is_clean else stage1_messy
		2:
			hair.texture = stage2_clean if is_clean else stage2_messy
		3:
			hair.texture = stage3_clean if is_clean else stage3_messy


func _update_charrax_face():
	var ratio = float(points) / next_stage_points

	if ratio < 0.33:
		charrax_face.texture = face_neutral
	elif ratio < 0.75:
		charrax_face.texture = face_happy
	else:
		charrax_face.texture = face_amazed


# --------------------------------------------------------------------
# PROGRESS BAR COLOR SYSTEM
# --------------------------------------------------------------------
func _update_progress_bar():
	var ratio = float(points) / next_stage_points

	if ratio < 0.3:
		_set_bar_color(Color(1, 0.25, 0.25))  # Red
	elif ratio < 0.7:
		_set_bar_color(Color(1, 0.85, 0.1))   # Yellow
	else:
		_set_bar_color(Color(0.3, 1, 0.3))    # Green


func _set_bar_color(color: Color):
	var style = progress_bar.get_theme_stylebox("fill")
	if style:
		style.set("bg_color", color)


# --------------------------------------------------------------------
# Word Effects
# --------------------------------------------------------------------
func _spawn_word():
	if word_textures.is_empty():
		return

	var texture = word_textures.pick_random()
	var word_sprite = Sprite2D.new()
	word_sprite.texture = texture

	word_container.add_child(word_sprite)

	# Appear just above the comb
	var offset = Vector2(randf_range(-30, 30), -60)
	word_sprite.global_position = comb.global_position + offset

	word_sprite.scale = Vector2(0.15, 0.15)
	word_sprite.modulate = Color(1, 1, 1, 1)

	var tween = create_tween()

	# Pop
	tween.tween_property(
		word_sprite,
		"scale",
		Vector2(0.25, 0.25),
		0.12
	).set_trans(Tween.TRANS_BOUNCE)

	# Float up and fade
	tween.parallel().tween_property(
		word_sprite,
		"position:y",
		word_sprite.position.y - 70,
		0.7
	)
	tween.parallel().tween_property(
		word_sprite,
		"modulate:a",
		0.0,
		0.7
	)

	tween.connect("finished", Callable(word_sprite, "queue_free"))


# --------------------------------------------------------------------
# Floating Points PNG that follows comb then floats away
# --------------------------------------------------------------------
func _spawn_points_follow():
	if points_texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = points_texture
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate = Color(1, 1, 1, 1)
	word_container.add_child(sprite)

	var x_offset_range := Vector2(-50, 100)
	var y_offset := -100
	var random_x := randf_range(x_offset_range.x, x_offset_range.y)
	var offset := Vector2(random_x, y_offset)

	sprite.global_position = comb.global_position + offset

	sprite.set_meta("offset", offset)
	sprite.set_meta("timer", 0.0)
	sprite.set_meta("follow_time", 0.3)
	sprite.set_meta("float_time", 0.6)

	active_point_sprites.append(sprite)


# --------------------------------------------------------------------
# Finish Button
# --------------------------------------------------------------------
func _show_win_button():
	var button := Button.new()
	button.text = "Brushalicious! His hair looks amazing! Press here to continue...or keep brushing his hair."
	button.scale = Vector2(1, 1)
	button.position = get_viewport_rect().size / 2 - Vector2(350, 50)
	button.set_anchors_preset(Control.PRESET_CENTER)

	add_child(button)
	button.connect("pressed", Callable(self, "_on_win_button_pressed"))

	button.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(button, "modulate:a", 1.0, 0.5)


func _on_win_button_pressed():
	Global.resume_after_minigame = true
	Global.resume_line_id = "next_fighters"
	get_tree().change_scene_to_file("res://Main Game/Scenes/FirstScene.tscn")
