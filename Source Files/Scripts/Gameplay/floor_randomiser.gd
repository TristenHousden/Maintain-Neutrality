extends TileMapLayer

var overlay_percentage := 50 # percentage

const OVERLAY_TILES = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)]
const OVERLAY_RADIUS = 15

const TILE_SIZE = 32
const CHUNK_SIZE = 16
@onready var player : Node2D = null
const REPLACE_TILE = [Vector2i(0, 0)]

var overlayed_tiles := {} # tile_pos: {source_id, atlas_coords}
var _last_player_tile := Vector2i(-9999, -9999)
var _initialized := false

func _ready():
	player = get_tree().get_root().find_child("Player", true, false)
	randomize()

func _process(_delta):
	if not is_instance_valid(player):
		return

	# Only activate if both torch and lantern are not visible
	if player.player_light_torch.visible or player.player_light_lantern.visible:
		return

	var player_tile = Vector2i(
		floor(player.global_position.x / TILE_SIZE),
		floor(player.global_position.y / TILE_SIZE)
	)

	if player_tile != _last_player_tile:
		place_random_overlays_around_player(player_tile)
		_last_player_tile = player_tile

func place_random_overlays_around_player(player_tile: Vector2i):
	var new_overlayed_tiles = {}
	var eligible_tiles := []
	var edge_tiles := []

	for dx in range(-OVERLAY_RADIUS, OVERLAY_RADIUS + 1):
		for dy in range(-OVERLAY_RADIUS, OVERLAY_RADIUS + 1):
			var dist = abs(dx) + abs(dy)
			if dist > OVERLAY_RADIUS:
				continue

			var tile_pos = player_tile + Vector2i(dx, dy)
			new_overlayed_tiles[tile_pos] = true

			var source_id = get_cell_source_id(tile_pos)
			var atlas_coords = get_cell_atlas_coords(tile_pos)

			if source_id != -1 and atlas_coords in REPLACE_TILE and not overlayed_tiles.has(tile_pos):
				if not _initialized:
					eligible_tiles.append(tile_pos)
				elif dist == OVERLAY_RADIUS:
					edge_tiles.append(tile_pos)

	if not _initialized:
		eligible_tiles.shuffle()
		var num_to_replace = int(floor(overlay_percentage / 100.0 * eligible_tiles.size()))
		for i in range(num_to_replace):
			var tile_pos = eligible_tiles[i]
			var source_id = get_cell_source_id(tile_pos)
			var atlas_coords = get_cell_atlas_coords(tile_pos)
			var overlay_atlas = OVERLAY_TILES[randi() % OVERLAY_TILES.size()]
			overlayed_tiles[tile_pos] = { "source_id": source_id, "atlas_coords": atlas_coords }
			set_cell(tile_pos, source_id, overlay_atlas)
		_initialized = true
	else:
		edge_tiles.shuffle()
		var num_to_replace = int(floor(overlay_percentage / 100.0 * edge_tiles.size()))
		for i in range(num_to_replace):
			var tile_pos = edge_tiles[i]
			var source_id = get_cell_source_id(tile_pos)
			var atlas_coords = get_cell_atlas_coords(tile_pos)
			var overlay_atlas = OVERLAY_TILES[randi() % OVERLAY_TILES.size()]
			
			if atlas_coords in REPLACE_TILE and overlay_atlas in OVERLAY_TILES:
				set_cell(tile_pos, source_id, overlay_atlas)
				overlayed_tiles[tile_pos] = { "source_id": source_id, "atlas_coords": atlas_coords }

	var to_remove := []
	for tile_pos in overlayed_tiles.keys():
		var dist = abs(tile_pos.x - player_tile.x) + abs(tile_pos.y - player_tile.y)
		if dist > OVERLAY_RADIUS or not new_overlayed_tiles.has(tile_pos):
			var original = overlayed_tiles[tile_pos]
			set_cell(tile_pos, original.source_id, original.atlas_coords)
			to_remove.append(tile_pos)
	for tile_pos in to_remove:
		overlayed_tiles.erase(tile_pos)

	print("Overlayed tiles count: ", overlayed_tiles.size())
