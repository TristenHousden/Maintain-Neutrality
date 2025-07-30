extends Control

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	set_position(Vector2.ZERO)
	var back_button = find_child("BackButton", true, false)
	if back_button:
		back_button.grab_focus()
