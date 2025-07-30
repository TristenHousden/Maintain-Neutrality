extends Control

signal resume_pressed
signal restart_pressed
signal main_menu_pressed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_node("Panel/HBoxContainer/VBoxContainer/ResumeButton").pressed.connect(_on_resume_pressed)
	get_node("Panel/HBoxContainer/VBoxContainer/RestartButton").pressed.connect(_on_restart_pressed)
	get_node("Panel/HBoxContainer/VBoxContainer/MainMenuButton").pressed.connect(_on_main_menu_pressed)
	visible = false

func show_menu():
	visible = true
	set_process_input(true)
	get_tree().paused = true
	get_node("Panel/HBoxContainer/VBoxContainer/ResumeButton").grab_focus()

func hide_menu():
	visible = false
	set_process_input(false)
	get_tree().paused = false

func _on_resume_pressed():
	hide_menu()
	emit_signal("resume_pressed")

func _on_restart_pressed():
	get_tree().paused = false
	emit_signal("restart_pressed")

func _on_main_menu_pressed():
	get_tree().paused = false
	emit_signal("main_menu_pressed")

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
