extends Control

const GAME_SCENE_PATH = "res://Scenes/Gameplay/main_scene.tscn"

const LICENSES_CREDITS_SCENE_PATH = "res://Scenes/Menu/licenses_credits_menu.tscn"

@onready var play_button = $"ButtonContainer/PlayButton"
@onready var licenses_credits_button = $"ButtonContainer/LicensesCreditsButton"
@onready var quit_button = $"ButtonContainer/QuitButton"

var licenses_credits_menu_instance: Control = null

func _ready():
	play_button.grab_focus() 

	play_button.pressed.connect(_on_PlayButton_pressed)
	licenses_credits_button.pressed.connect(_on_LicensesCreditsButton_pressed)
	quit_button.pressed.connect(_on_QuitButton_pressed)

	var licenses_credits_scene = load(LICENSES_CREDITS_SCENE_PATH)
	if licenses_credits_scene:
		licenses_credits_menu_instance = licenses_credits_scene.instantiate()
		add_child(licenses_credits_menu_instance)
		licenses_credits_menu_instance.hide() # Hide it initially
		# Connect the BackButton's pressed signal from the instanced scene
		var back_button = licenses_credits_menu_instance.find_child("BackButton", true, false)
		if back_button:
			back_button.pressed.connect(_on_BackButton_pressed)
		else:
			push_error("LicensesCreditsMenu: BackButton not found! Check its name and path.")
	else:
		push_error("Licenses/Credits scene not found at path: " + LICENSES_CREDITS_SCENE_PATH)

func _on_PlayButton_pressed():
	Global.has_won = false
	# Change to the main game scene
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_LicensesCreditsButton_pressed():
	if licenses_credits_menu_instance:
		licenses_credits_menu_instance.show()
		licenses_credits_menu_instance.set_position(Vector2.ZERO)
		licenses_credits_menu_instance.set_anchors_preset(Control.PRESET_CENTER)
		play_button.hide()
		licenses_credits_button.hide()
		quit_button.hide()
		var back_button = licenses_credits_menu_instance.find_child("BackButton", true, false)
		if back_button:
			back_button.grab_focus()
		else:
			print("BackButton not found in licenses_credits_menu_instance")
	else:
		push_error("Licenses/Credits menu instance not found! (Did it fail to load in _ready()?)")

func _on_QuitButton_pressed():
	print("Quit button pressed!")
	# Stop all audio players
	for node in get_tree().get_nodes_in_group("audio_player"):
		if node is AudioStreamPlayer:
			node.stop()
	# Stop all timers
	for timer in get_tree().get_nodes_in_group("Timer"):
		if timer is Timer:
			timer.stop()
			timer.queue_free()
	# Explicitly free gameplay scene if present
	var gameplay_scene = get_tree().get_root().find_child("MainScene", true, false)
	if gameplay_scene:
		gameplay_scene.queue_free()
	for agent in get_tree().get_nodes_in_group("NavigationAgent2D"):
		if agent is NavigationAgent2D:
			agent.set_physics_process(false)
			agent.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_node("NavigationAgent2D"):
			var nav_agent = enemy.get_node("NavigationAgent2D")
			nav_agent.set_physics_process(false)
			nav_agent.queue_free()
	for particle in get_tree().get_nodes_in_group("CPUParticles2D"):
		if particle is CPUParticles2D:
			particle.emitting = false
			particle.queue_free()
	# Print node types before quitting
	for node in get_tree().get_root().get_children():
		print("Node type: ", node.get_class())
	get_tree().quit()
	OS.kill(OS.get_process_id())

func _on_BackButton_pressed():
	print("Back button pressed from Licenses & Credits!")
	if licenses_credits_menu_instance:
		licenses_credits_menu_instance.hide()
		play_button.show()
		licenses_credits_button.show()
		quit_button.show()
		play_button.grab_focus()
