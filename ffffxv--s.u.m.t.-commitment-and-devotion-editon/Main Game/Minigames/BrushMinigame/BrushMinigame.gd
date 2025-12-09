extends Node2D

@onready var comb = $CharraxComb
@onready var hair = $Hair
@onready var word_container = $WordContainer

@onready var score_label = $CanvasLayer/UI/ScoreLabel
@onready var charrax_face = $CanvasLayer/UI/CharraxFace

var face_neutral = load("res://Assets/MinigameAssets/BrushMini/CharraxRighMessy.png")
var face_happy = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")
var face_amazed = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")

var stage1_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxLeftMessy.png")
var stage1_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxLeftNeat.png")
var stage2_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxBackMessy.png")
var stage2_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxBackNeat.png")
var stage3_messy = load("res://Assets/MinigameAssets/BrushMini/CharraxRighMessy.png")
var stage3_clean = load("res://Assets/MinigameAssets/BrushMini/CharraxRightNeat.png")

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

var points_texture = load("res://Assets/MinigameAssets/BrushMini/PointPlaceholder.png")

var stage := 1
var is_clean := false
var points := 0
var next_stage_points := 30
var can_earn_points := true

var previous_comb_y := 0.0
var brushing_cooldown := 0.0

var active_point_sprites: Array = []


func _ready():
	randomize()
	_set_hair_texture()
	previous_comb_y = comb.global_position.y

	score_label.text = "Score: %d / %d" % [points, next_stage_points]
	charrax_face.texture = face_neutral

func _process(delta):
	if comb.dragging:
		_check_brushing(delta)
	previous_comb_y = comb.global_position.y

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
	if not can_earn_points:
		return
	if brushing_cooldown > 0:
		brushing_cooldown -= delta
		return

	if _is_brushing_on_head():
		var moving_down = comb.global_position.y > previous_comb_y + 2
		if moving_down:
			points += 1
			brushing_cooldown = 0.05
			_spawn_points_follow()

			_update_score_label()
			_update_charrax_face()

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
	_update_score_label()
	charrax_face.texture = face_neutral
	can_earn_points = false
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
		can_earn_points = true
	else:
		_set_hair_texture()
		can_earn_points = true

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

func _update_score_label():
	score_label.text = "Score: %d / %d" % [points, next_stage_points]

func _is_brushing_on_head() -> bool:
	var comb_rect = Rect2(comb.global_position - comb.texture.get_size() * comb.scale * 0.5, comb.texture.get_size() * comb.scale)
	var hair_rect = Rect2(hair.global_position - hair.texture.get_size() * hair.scale * 0.5, hair.texture.get_size() * hair.scale)
	return comb_rect.intersects(hair_rect)

func _spawn_word():
	if word_textures.is_empty():
		return

	var texture = word_textures.pick_random()
	var word_sprite = Sprite2D.new()
	word_sprite.texture = texture

	word_container.add_child(word_sprite)

	var offset = Vector2(randf_range(-30, 30), -60)
	word_sprite.global_position = comb.global_position + offset

	word_sprite.scale = Vector2(0.15, 0.15)

	var tween = create_tween()

	tween.tween_property(word_sprite, "scale", Vector2(0.25, 0.25), 0.12).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(word_sprite, "position:y", word_sprite.position.y - 70, 0.7)
	tween.parallel().tween_property(word_sprite, "modulate:a", 0.0, 0.7)

	tween.connect("finished", Callable(word_sprite, "queue_free"))

func _spawn_points_follow():
	if points_texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = points_texture
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate = Color(1, 1, 1, 1)
	word_container.add_child(sprite)

	var random_x := randf_range(-50, 100)
	var offset := Vector2(random_x, -100)

	sprite.global_position = comb.global_position + offset

	sprite.set_meta("offset", offset)
	sprite.set_meta("timer", 0.0)
	sprite.set_meta("follow_time", 0.3)
	sprite.set_meta("float_time", 0.6)

	active_point_sprites.append(sprite)

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
