extends Control

@onready var respawn_button = $Canvas/Control/RespawnButton
@onready var menu_button = $Canvas/Control/MenuButton
@onready var timer_label = $Canvas/Control/TimerLabel
@onready var audio_player = $Canvas/WinAudio

func _ready():
	respawn_button.pressed.connect(_on_RespawnButton_pressed)
	menu_button.pressed.connect(_on_MenuButton_pressed)
	if audio_player and audio_player.stream:
		audio_player.play()

func set_time_taken(time_in_seconds: float):
	var minutes = floor(time_in_seconds / 60)
	var seconds = fmod(time_in_seconds, 60)
	timer_label.text = "Time: %02d:%05.2f" % [minutes, seconds] # Format to 2 decimal places for seconds

func _on_RespawnButton_pressed():
	get_tree().paused = false
	var win_canvas_layer = get_tree().root.get_node_or_null("WinScreenCanvas")
	if win_canvas_layer:
		win_canvas_layer.queue_free()
	get_tree().change_scene_to_file("res://Scenes/Gameplay/main_scene.tscn")

func _on_MenuButton_pressed():
	get_tree().paused = false
	var win_canvas_layer = get_tree().root.get_node_or_null("WinScreenCanvas")
	if win_canvas_layer:
		win_canvas_layer.queue_free()
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
