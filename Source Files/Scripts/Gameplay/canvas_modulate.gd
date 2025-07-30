extends CanvasModulate

var _darkness_cheat_sequence := ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept"]
var _darkness_cheat_progress := 0

func _process(_delta):
	# Hide CanvasModulate if cheat sequence is entered
	if visible and Input.is_action_just_pressed(_darkness_cheat_sequence[_darkness_cheat_progress]):
		_darkness_cheat_progress += 1
		if _darkness_cheat_progress >= _darkness_cheat_sequence.size():
			visible = false
			_darkness_cheat_progress = 0
	elif visible and Input.is_action_just_pressed(_darkness_cheat_sequence[0]) and _darkness_cheat_progress > 0:
		_darkness_cheat_progress = 1
	elif visible and Input.is_action_just_pressed("ui_accept") and _darkness_cheat_progress != _darkness_cheat_sequence.size() - 1:
		_darkness_cheat_progress = 0

	# Show CanvasModulate again if cheat sequence is entered a second time
	if not visible and Input.is_action_just_pressed(_darkness_cheat_sequence[_darkness_cheat_progress]):
		_darkness_cheat_progress += 1
		if _darkness_cheat_progress >= _darkness_cheat_sequence.size():
			visible = true
			_darkness_cheat_progress = 0
	elif not visible and Input.is_action_just_pressed(_darkness_cheat_sequence[0]) and _darkness_cheat_progress > 0:
		_darkness_cheat_progress = 1
	elif not visible and Input.is_action_just_pressed("ui_accept") and _darkness_cheat_progress != _darkness_cheat_sequence.size() - 1:
		_darkness_cheat_progress = 0
