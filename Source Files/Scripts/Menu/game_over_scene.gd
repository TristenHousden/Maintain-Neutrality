extends Control

@onready var respawn_button = $RespawnButton
@onready var menu_button = $MenuButton
@onready var audio_player = $GameOverAudio

func _ready():
	respawn_button.pressed.connect(_on_RespawnButton_pressed)
	menu_button.pressed.connect(_on_MenuButton_pressed)
	if audio_player and audio_player.stream:
		audio_player.play()

func _on_RespawnButton_pressed():
	Global.has_won = false
	get_tree().change_scene_to_file("res://Scenes/Gameplay/main_scene.tscn")

func _on_MenuButton_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
