extends Node

var _pause_menu: Control = null

func _ready():
	var pause_menu = get_node("PauseMenuCanvas/PauseMenu")
	pause_menu.hide_menu()
	pause_menu.resume_pressed.connect(_on_pause_resume)
	pause_menu.restart_pressed.connect(_on_pause_restart)
	pause_menu.main_menu_pressed.connect(_on_pause_main_menu)
	_pause_menu = pause_menu

func show_pause_menu():
	if _pause_menu:
		_pause_menu.show_menu()

func hide_pause_menu():
	if _pause_menu:
		_pause_menu.hide_menu()

func _on_pause_resume():
	hide_pause_menu()
	var player = get_node_or_null("WorldMap/characters/player")
	if player and player.has_method("_on_pause_menu_closed"):
		player._on_pause_menu_closed()

func _on_pause_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Menu/main_menu.tscn")
