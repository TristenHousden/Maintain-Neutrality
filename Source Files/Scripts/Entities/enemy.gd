extends CharacterBody2D
class_name Enemy

@export var speed_none := 10.0
@export var speed_torch := 80.0
@export var speed_lantern := 20.0
@export var speed_both := 100.0
@export var speed_sprint := 200.0

var speed := 200.0

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var enemy_sprite = $EnemySprite
@onready var game_over_detector = $GameOverDetector
@onready var enemy_collision = $EnemyCollision

@onready var leg_front_right = $LegsContainer/Leg_FrontRight
@onready var leg_back_right = $LegsContainer/Leg_BackRight  
@onready var leg_front_left = $LegsContainer/Leg_FrontLeft  
@onready var leg_back_left = $LegsContainer/Leg_BackLeft   

@export var base_leg_anim_speed_scale := 0.5
@export var max_leg_anim_speed_scale := 2.0

var player: CharacterBody2D = null

var stuck_timer := 0.0
var last_position := Vector2.ZERO
var stuck_threshold := 0.5 # seconds
var stuck_distance := 4.0 # pixels

@export var game_over_delay := 1.5 # seconds to wait before switching to game over scene
@export var game_over_sound: AudioStream = null
var _game_over_timer : float = 0
var _game_over_triggered := false
var _game_over_audio_player: AudioStreamPlayer = null
var _endgame_speed_override: Variant = null

var _path_update_timer := 0.0
const PATH_UPDATE_INTERVAL := 5.0

func _ready() -> void:
	_game_over_triggered = false
	_game_over_timer = 0.0
	player = null
	var player_candidates = get_tree().get_nodes_in_group("player")
	if player_candidates.size() > 0:
		player = player_candidates[0]
	else:
		var root = get_tree().current_scene
		if root:
			player = root.find_child("Player", true, false)
	if player == null:
		push_error("Enemy: Player node not found! Pathfinding will not work.")
		set_physics_process(false)
		return
	nav.avoidance_enabled = false
	nav.radius = 15.0
	actor_setup.call_deferred()
	nav.velocity_computed.connect(_velocity_computed)
	if game_over_detector and game_over_detector.has_signal("body_entered"):
		game_over_detector.body_entered.connect(_on_GameOverDetector_body_entered)
	last_position = global_position
	_game_over_audio_player = AudioStreamPlayer.new()
	add_child(_game_over_audio_player)

	leg_front_right.animation = "walk"
	leg_back_right.animation = "walk"
	leg_front_left.animation = "walk"
	leg_back_left.animation = "walk"

	var walk_frame_count = leg_front_right.sprite_frames.get_frame_count("walk")
	var halfway_frame = int(floor(float(walk_frame_count) / 2.0))
	leg_front_left.frame = halfway_frame
	leg_back_right.frame = halfway_frame

	leg_front_right.play()
	leg_back_right.play()
	leg_front_left.play()
	leg_back_left.play()
	_update_leg_animation_speed(speed)
	add_to_group("enemy")

func actor_setup():
	await get_tree().physics_frame
	set_movement_target(player.position)

func set_movement_target(movement_target: Vector2):
	nav.target_position = movement_target

func _physics_process(delta: float) -> void:
	if _game_over_triggered:
		_game_over_timer += delta
		if _game_over_timer >= game_over_delay:
			get_tree().change_scene_to_file("res://Scenes/Gameplay/game_over_scene.tscn")
		return

	_path_update_timer += delta
	if _path_update_timer >= PATH_UPDATE_INTERVAL:
		set_movement_target(player.position)
		_path_update_timer = 0.0

	_move_towards_player()
	_check_unstuck(delta)
	_update_leg_animation_speed(speed)

func _move_towards_player() -> void:
	var torch_on := false
	var lantern_on := false
	var sprinting := false
	if player:
		if "player_light_torch" in player:
			torch_on = player.player_light_torch.visible
		if "player_light_lantern" in player:
			lantern_on = player.player_light_lantern.visible
		if player.has_method("is_sprinting"):
			sprinting = player.is_sprinting()
		elif "_current_actual_speed" in player and "sprint_speed" in player:
			sprinting = player._current_actual_speed >= player.sprint_speed * 0.95

	_endgame_speed_override = Global.endgame_enemy_speed

	if _endgame_speed_override != null:
		speed = _endgame_speed_override
	elif sprinting:
		speed = speed_sprint
	elif torch_on and lantern_on:
		speed = speed_both
	elif torch_on:
		speed = speed_torch
	elif lantern_on:
		speed = speed_lantern
	else:
		speed = speed_none

	if nav.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_leg_animation_speed(0.0)
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = nav.get_next_path_position()
	var new_velocity = current_agent_position.direction_to(next_path_position) * speed
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_velocity_computed(new_velocity)
	move_and_slide()

	if velocity.length() > 1e-2:
		rotation = velocity.angle() + PI / 2
	if nav.max_speed != speed:
		nav.max_speed = speed

func _velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity

func _update_leg_animation_speed(current_enemy_speed: float) -> void:
	var anim_speed_scale: float = 0.0
	var max_defined_speed = max(speed_none, speed_torch, speed_lantern, speed_both, speed_sprint, 1.0)
	if current_enemy_speed < 1.0:
		anim_speed_scale = 0.0
	else:
		var speed_ratio = inverse_lerp(speed_none, max_defined_speed, current_enemy_speed)
		speed_ratio = clamp(speed_ratio, 0.0, 1.0)
		anim_speed_scale = lerp(base_leg_anim_speed_scale, max_leg_anim_speed_scale, speed_ratio)
	leg_front_right.speed_scale = anim_speed_scale
	leg_back_right.speed_scale = anim_speed_scale
	leg_front_left.speed_scale = anim_speed_scale
	leg_back_left.speed_scale = anim_speed_scale

func _check_unstuck(delta: float) -> void:
	if nav.is_navigation_finished():
		stuck_timer = 0.0
		last_position = global_position
		return
	if global_position.distance_to(last_position) < stuck_distance:
		stuck_timer += delta
		if stuck_timer > stuck_threshold:
			set_movement_target(player.position)
			nav.target_position = player.position
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		last_position = global_position

func _on_GameOverDetector_body_entered(_body):
	if Global.has_won:
		return
	if _body == player and not _game_over_triggered:
		_game_over_triggered = true
		_game_over_timer = 0.0
		if player.has_method("disable_controls"):
			player.disable_controls()
		else:
			if "player_light_torch" in player:
				player.player_light_torch.visible = false
			if "player_light_lantern" in player:
				player.player_light_lantern.visible = false
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			player.set_physics_process(false)
		if game_over_sound:
			_game_over_audio_player.stream = game_over_sound
			_game_over_audio_player.play()
