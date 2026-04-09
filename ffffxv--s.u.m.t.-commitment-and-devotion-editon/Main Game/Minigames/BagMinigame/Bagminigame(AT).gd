extends Node2D

@onready var bag: Sprite2D = $BagSprite
@onready var popup: Sprite2D = $PunchPopup
@onready var timer: Timer = $PunchTimer
@onready var prompt: Label = $LabelPrompt
@onready var start_button: Button = $StartButton
@onready var punch_sfx: AudioStreamPlayer = $PunchSFX


var game_finished := false
var punch_count := 0
var game_active := false


const BAG_CLEAN   = preload("res://Assets/MinigameAssets/BagMini/BagClean.png")
const BAG_PUNCH   = preload("res://Assets/MinigameAssets/BagMini/BagPunch.png")
const BAG_SCUFFED = preload("res://Assets/MinigameAssets/BagMini/BagScuffed.png")

const POPUPS = [
	preload("res://Assets/MinigameAssets/BrushMini/harder.png"),
	preload("res://Assets/MinigameAssets/BrushMini/encouragement.png"),
	preload("res://Assets/MinigameAssets/BrushMini/yeah-baby-keep-going.png")
]

func _ready():
	bag.texture = BAG_CLEAN
	popup.visible = false
	prompt.text = "Get ready! Press I'M READY when you're ready to punch."
	game_active = false 

func _on_start_button_pressed():
	if game_finished:
		get_tree().reload_current_scene()
		return

	punch_count = 0
	game_active = true
	game_finished = false

	prompt.text = "Punch the bag as fast as you can!"
	start_button.visible = false
	bag.texture = BAG_CLEAN
	
	timer.start()


func _input(event):
	if not game_active:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = bag.to_local(event.position)
			if bag.get_rect().has_point(local_pos):
				register_punch()

func register_punch():
	if not game_active:
		return
	punch_sfx.play()
	punch_count += 1
	
	bag.texture = BAG_PUNCH
	await get_tree().create_timer(0.08).timeout
	bag.texture = BAG_CLEAN
	
	show_popup()

func show_popup():
	if popup.has_meta("tween"):
		var old_tween: Tween = popup.get_meta("tween")
		if old_tween.is_valid():
			old_tween.kill()

	popup.visible = true
	popup.texture = POPUPS.pick_random()
	popup.modulate = Color(1,1,1,1)
	popup.position = Vector2(578.0, 258.0)

	var tween = create_tween()
	popup.set_meta("tween", tween)

	tween.tween_property(popup, "position", popup.position + Vector2(0, -40), 0.55)
	tween.parallel().tween_property(popup, "modulate:a", 0, 0.55)
	tween.tween_callback(func(): popup.visible = false)


func _on_punch_timer_timeout():
	game_active = false
	game_finished = true

	bag.texture = BAG_SCUFFED
	prompt.text = "You only hit it %s times... Your punches were really weak." % punch_count

	_finish_punch_minigame()

func _finish_punch_minigame():
	var b := Button.new()
	b.text = "Your punches were... something"
	b.scale = Vector2(1.5, 1.5)
	add_child(b)

	await get_tree().process_frame

	var vp = get_viewport_rect().size
	var bs = b.size
	b.position = vp / 2 - bs / 2 + Vector2(-50, -100)
	b.pressed.connect(_on_finish_pressed)


func _on_finish_pressed():
	Global.resume_after_minigame = true
	Global.resume_line_id = "punch_1"
	get_tree().change_scene_to_file("res://Main Game/Scenes/TempleScene(AT).tscn")
