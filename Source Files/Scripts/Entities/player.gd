extends CharacterBody2D

@export var base_speed := 200.0
@export var sprint_speed := 500.0
@export var acceleration_factor := 5.0
@export var rotation_smoothing_speed := 3.0
@export var camera_revolve_speed := PI / 180.0
@export var _was_lantern_active_this_frame := false

@onready var player_sprite := $PlayerSprite
@onready var player_camera := $PlayerCamera
@onready var player_light_torch := $PlayerSprite/LightSprite/PlayerTorch
@onready var player_light_lantern := $PlayerSprite/LightSprite/PlayerLantern
@onready var lantern_sound := $PlayerSprite/LightSprite/PlayerLantern/LanternSound
@onready var torch_sound := $PlayerSprite/LightSprite/PlayerTorch/TorchSound
@onready var lantern_fire_particles := $PlayerSprite/LightSprite/PlayerLantern/LanternFireParticles

@onready var win_tile_layer := get_node_or_null("/root/MainScene/WorldMap/TriggerTiles")
@onready var door_tile_layer := get_node_or_null("/root/MainScene/WorldMap/NavigationRegion2D/DoorTiles")

@export var transition_duration := 1.0
var _is_winning := false
var _win_fade_tween: Tween = null

var _current_actual_speed := 0.0
var _was_torch_visible := false
var _was_lantern_visible := false
var _last_cell_pos_for_door_logic := Vector2i(-9999, -9999)
var _controls_disabled := false
var _pause_menu_just_closed := false

@export var endgame_enemy_speed := 1000.0
@export var endgame_audio: AudioStream = null
@export var endgame_time_minutes := 49.0
@export var camera_rotation_time_minutes := 7.0

var _rotation_time_seconds := 420.0
var _rotation_speed := 0.0
var _endgame_timer: Timer = null
var _endgame_timer_started := false
var _endgame_triggered := false
var _endgame_audio_player: AudioStreamPlayer = null

func _ready():
	_current_actual_speed = base_speed
	player_light_torch.visible = false
	player_light_lantern.visible = false
	lantern_sound.stop()
	torch_sound.stop()
	_was_torch_visible = false
	_was_lantern_visible = false
	lantern_fire_particles.emitting = false

	_rotation_time_seconds = (camera_rotation_time_minutes if camera_rotation_time_minutes != null else 7.0) * 60.0
	_rotation_speed = 2 * PI / _rotation_time_seconds
	camera_revolve_speed = _rotation_speed

	reset_endgame_timer()
	_endgame_audio_player = AudioStreamPlayer.new()
	add_child(_endgame_audio_player)
	add_to_group("player")

func reset_endgame_timer():
	_endgame_timer_started = false
	_endgame_triggered = false
	if _endgame_timer and is_instance_valid(_endgame_timer):
		_endgame_timer.stop()
		_endgame_timer.queue_free()
		_endgame_timer = null
	Global.endgame_enemy_speed = null
	if endgame_time_minutes <= 0.0:
		_on_endgame_timer_timeout()
		_endgame_timer_started = true
	else:
		_endgame_timer = Timer.new()
		_endgame_timer.wait_time = endgame_time_minutes * 60.0
		_endgame_timer.one_shot = true
		_endgame_timer.timeout.connect(_on_endgame_timer_timeout)
		add_child(_endgame_timer)
		_endgame_timer.start()
		_endgame_timer_started = true

func disable_controls():
	_controls_disabled = true
	Global.has_won = true
	velocity = Vector2.ZERO
	player_light_torch.visible = false
	player_light_lantern.visible = false
	lantern_sound.stop()
	torch_sound.stop()

func _physics_process(delta):
	if _controls_disabled:
		velocity = Vector2.ZERO
		return

	if not _is_winning:
		check_win_condition()

	var input_direction_screen_relative = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction_screen_relative.length() > 0.01:
		var target_speed = base_speed
		if Input.is_action_pressed("sprint"):
			target_speed = sprint_speed
		_current_actual_speed = lerp(_current_actual_speed, target_speed, delta * acceleration_factor)
		var camera_global_rotation = player_camera.global_rotation
		var movement_vector_camera_relative = input_direction_screen_relative.rotated(camera_global_rotation)
		velocity = movement_vector_camera_relative * _current_actual_speed
		move_and_slide()

	if door_tile_layer and door_tile_layer.has_method("_on_player_moved"):
		var cell_pos = door_tile_layer.local_to_map(global_position)
		if _last_cell_pos_for_door_logic == Vector2i(-9999, -9999) or cell_pos != _last_cell_pos_for_door_logic:
			door_tile_layer._on_player_moved(cell_pos)
			_last_cell_pos_for_door_logic = cell_pos

func _process(delta):
	if _controls_disabled:
		return

	if _pause_menu_just_closed:
		_pause_menu_just_closed = false
		return

	var root = get_tree().current_scene
	var pause_menu_visible = false
	if root and root.has_node("PauseMenuCanvas/PauseMenu"):
		pause_menu_visible = root.get_node("PauseMenuCanvas/PauseMenu").visible
	if not get_tree().paused and not pause_menu_visible and Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause_menu()

	var mouse_position = get_global_mouse_position()
	var player_sprite_position = player_sprite.global_position
	var direction_to_mouse = mouse_position - player_sprite_position
	var target_angle = direction_to_mouse.angle() + PI / 2
	player_sprite.rotation = lerp_angle(player_sprite.rotation, target_angle, delta * rotation_smoothing_speed)
	player_camera.rotation += camera_revolve_speed * delta

	var is_torch_active_this_frame = Input.is_action_pressed("toggle_torch")
	player_light_torch.visible = is_torch_active_this_frame
	if is_torch_active_this_frame != _was_torch_visible:
		torch_sound.play()
	_was_torch_visible = is_torch_active_this_frame

	var is_lantern_active_this_frame = Input.is_action_pressed("toggle_lantern")
	player_light_lantern.visible = is_lantern_active_this_frame
	if is_lantern_active_this_frame and not _was_lantern_visible:
		lantern_sound.play()
	_was_lantern_active_this_frame = is_lantern_active_this_frame

	lantern_fire_particles.emitting = player_light_lantern.visible

func _toggle_pause_menu():
	if get_tree().paused:
		return
	var root = get_tree().current_scene
	if root and root.has_method("show_pause_menu"):
		root.show_pause_menu()

func _on_pause_menu_closed():
	_pause_menu_just_closed = true

func _on_endgame_timer_timeout():
	_endgame_triggered = true
	if endgame_audio:
		_endgame_audio_player.stream = endgame_audio
		_endgame_audio_player.play()
	Global.endgame_enemy_speed = endgame_enemy_speed

func is_endgame_triggered():
	return _endgame_triggered

func check_win_condition():
	if not win_tile_layer:
		return
	var player_tile_pos = win_tile_layer.local_to_map(global_position)
	var tile_source_id = win_tile_layer.get_cell_source_id(player_tile_pos)
	if tile_source_id != -1:
		initiate_win_sequence()

func initiate_win_sequence():
	if _is_winning:
		return
	_is_winning = true
	Global.has_won = true
	disable_controls()

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("disable_controls"):
			enemy.disable_controls()
		else:
			enemy.set_physics_process(false)
			enemy.visible = false

	var transition_scene_path = "res://Scenes/Cutscenes/winner_transition.tscn"
	var transition_scene = load(transition_scene_path)
	if not transition_scene:
		push_error("Failed to load winner_transition.tscn")
		return
	var transition_canvas = transition_scene.instantiate()
	transition_canvas.name = "WinTransition"
	get_tree().root.add_child(transition_canvas)

	var color_rect = transition_canvas.get_node_or_null("ColorRect")
	if color_rect:
		color_rect.modulate = Color(1, 1, 1, 0)
		_win_fade_tween = create_tween()
		_win_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_win_fade_tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)
		_win_fade_tween.tween_interval(2.0)
		_win_fade_tween.tween_property(color_rect, "modulate:a", 0.0, 2.0)
		_win_fade_tween.tween_callback(Callable(self, "_load_win_screen"))
		_win_fade_tween.play()
	else:
		_load_win_screen()

func _load_win_screen():
	var transition_canvas = get_tree().root.get_node_or_null("WinTransition")
	if transition_canvas:
		transition_canvas.queue_free()

	var time_taken := 0.0
	if _endgame_timer and _endgame_timer_started:
		time_taken = _endgame_timer.wait_time - _endgame_timer.time_left
		if time_taken < 0: time_taken = 0.0

	var win_screen_path = "res://Scenes/Gameplay/WinScreen.tscn"
	var win_screen_scene = load(win_screen_path)
	if not win_screen_scene:
		push_error("Failed to load WinScreen.tscn")
		return
	var win_screen = win_screen_scene.instantiate()
	get_tree().root.add_child(win_screen)

	if win_screen.has_method("set_time_taken"):
		win_screen.set_time_taken(time_taken)

func get_time_taken() -> float:
	var time_taken := 0.0
	if _endgame_timer and _endgame_timer_started:
		time_taken = _endgame_timer.wait_time - _endgame_timer.time_left
		if time_taken < 0: time_taken = 0.0
	return time_taken

func _on_GameOverDetector_body_entered(_body):
	if Global.has_won:
		return

func _exit_tree():
	if _endgame_timer and is_instance_valid(_endgame_timer):
		print("Freeing endgame timer")
		_endgame_timer.stop()
		_endgame_timer.queue_free()
	if _win_fade_tween and is_instance_valid(_win_fade_tween):
		print("Freeing win fade tween")
		_win_fade_tween.stop_all()
		_win_fade_tween.queue_free()
