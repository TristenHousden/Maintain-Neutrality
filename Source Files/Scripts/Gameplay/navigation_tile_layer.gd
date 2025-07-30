extends TileMapLayer

var _obstacles: Array[TileMapLayer] = []

func _ready() -> void:
	_get_obstacle_layers()

func _get_obstacle_layers():
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is TileMapLayer and child != self:
				_obstacles.append(child)

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true

func _is_used_by_obstacle(coords: Vector2i) -> bool:
	for layer in _obstacles:
		if coords in layer.get_used_cells():
			var tile_data = layer.get_cell_tile_data(coords)
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				return true
	return false

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if _is_used_by_obstacle(coords):
		tile_data.set_navigation_polygon(0, null)
	else:
		pass
