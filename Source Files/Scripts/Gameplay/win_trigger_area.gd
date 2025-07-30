extends Area2D

@export var win_screen_scene_path: String = "res://Scenes/Gameplay/WinScreen.tscn"
var _win_triggered := false

func _ready():
	collision_layer = 8
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if _win_triggered:
		return
	if body.is_in_group("player"):
		_win_triggered = true
		body.disable_controls()
		_trigger_win_transition(body)

func _trigger_win_transition(player):
	var transition_scene = load("res://Scenes/Cutscenes/winner_transition.tscn")
	if not transition_scene:
		push_error("Failed to load winner_transition.tscn")
		return
	var transition_canvas = transition_scene.instantiate()
	var canvas_layer = get_tree().root.get_node_or_null("WinTransitionCanvas")
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "WinTransitionCanvas"
		get_tree().root.add_child(canvas_layer)
	canvas_layer.layer = 100
	canvas_layer.add_child(transition_canvas)

	if transition_canvas is Control:
		transition_canvas.z_index = 100

	var color_rect = transition_canvas.get_node("CanvasLayer/ColorRect")
	if color_rect:
		color_rect.z_index = 200
		color_rect.modulate = Color(1, 1, 1, 0)
		color_rect.visible = true

		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)
		tween.tween_callback(Callable(self, "_show_win_screen").bind(player))
		tween.tween_property(color_rect, "modulate:a", 0.0, 2.0)
		tween.tween_callback(Callable(self, "_remove_win_transition"))
		tween.play()
	else:
		_show_win_screen(player)

func _show_win_screen(player):
	var win_screen_scene = load(win_screen_scene_path)
	if not win_screen_scene:
		push_error("Failed to load WinScreen.tscn")
		return
	var win_screen = win_screen_scene.instantiate()
	var win_canvas_layer = get_tree().root.get_node_or_null("WinScreenCanvas")
	if not win_canvas_layer:
		win_canvas_layer = CanvasLayer.new()
		win_canvas_layer.name = "WinScreenCanvas"
		get_tree().root.add_child(win_canvas_layer)
	win_canvas_layer.add_child(win_screen)
	if win_screen is Control:
		win_screen.anchor_left = 0
		win_screen.anchor_top = 0
		win_screen.anchor_right = 1
		win_screen.anchor_bottom = 1
		win_screen.offset_left = 0
		win_screen.offset_top = 0
		win_screen.offset_right = 0
		win_screen.offset_bottom = 0
	if player.has_method("get_time_taken") and win_screen.has_method("set_time_taken"):
		win_screen.set_time_taken(player.get_time_taken())

func _remove_win_transition():
	var canvas_layer = get_tree().root.get_node_or_null("WinTransitionCanvas")
	if canvas_layer:
		canvas_layer.queue_free()
