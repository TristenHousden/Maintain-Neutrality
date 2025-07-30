extends TileMapLayer

@export var button_tile_coords: Array[Vector2i]
@export var pressed_tile_coords: Array[Vector2i]
@export var closed_tile_coords: Array[Vector2i]
@export var open_tile_coords: Array[Vector2i]
@export var button_sound: AudioStream
@export var door_check_radius: int = 24
@export var num_door_sets: int = 7 # Number of door/button sets to check

var button_activated := []
const DOOR_SOURCE_ID = 0
var _last_player_cell: Vector2i = Vector2i(-9999, -9999)

func _ready():
	button_activated.resize(button_tile_coords.size())
	for i in range(button_activated.size()):
		button_activated[i] = false

func get_tilemap() -> TileMap:
	var node = self.get_parent()
	while node and not node is TileMap:
		node = node.get_parent()
	return node

func _on_player_moved(cell_pos: Vector2i):
	if cell_pos == _last_player_cell:
		return
	_last_player_cell = cell_pos
	var atlas_coords = get_cell_atlas_coords(cell_pos)
	for i in range(min(num_door_sets, button_tile_coords.size())):
		if atlas_coords == button_tile_coords[i] and not button_activated[i]:
			set_cell(cell_pos, DOOR_SOURCE_ID, pressed_tile_coords[i], 0)
			button_activated[i] = true
			_play_button_sound()
		if button_activated[i]:
			for x in range(-door_check_radius, door_check_radius + 1):
				for y in range(-door_check_radius, door_check_radius + 1):
					if x == 0 and y == 0:
						continue
					if abs(x) + abs(y) > door_check_radius:
						continue
					var check_pos = cell_pos + Vector2i(x, y)
					var door_atlas = get_cell_atlas_coords(check_pos)
					if door_atlas == closed_tile_coords[i]:
						set_cell(check_pos, DOOR_SOURCE_ID, open_tile_coords[i], 0)

func _play_button_sound():
	var audio = AudioStreamPlayer.new()
	audio.stream = button_sound
	add_child(audio)
	audio.play()
	audio.connect("finished", Callable(audio, "queue_free"))
