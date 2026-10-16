extends TileMap

@export var variants_per_tile := 5
@export var half_size := 10  # 10 tiles in each direction (makes 21×21 grid)

func _ready():
	randomize()
	for y in range(-half_size, half_size + 1):
		for x in range(-half_size, half_size + 1):
			var rand_tile = randi() % variants_per_tile
			set_cell(0, Vector2i(x, y), 0, Vector2i(rand_tile, 0))
