extends Control

const DISPLAY_GRID_SIZE := 5         # 11x11 window around player
const TILE_DISPLAY_SIZE := 16         # each mini tile in pixels
const ATLAS_TILE_SIZE := 16           # source atlas tile size (your PNG)

# Atlas coords:
# 0,0 = empty/no room
# 1,0 = path
# 3,0 = goal
# 4,0 = start
# 5,0 = player
const ATLAS_EMPTY := Vector2i(0, 0)
const ATLAS_PATH  := Vector2i(1, 0)
const ATLAS_GOAL  := Vector2i(3, 0)
const ATLAS_START := Vector2i(4, 0)
const ATLAS_PLAYER:= Vector2i(5, 0)

@export var crawler_world_path: NodePath   # set this in the editor!
@onready var texture_rect: TextureRect = $TextureRect
@onready var tile_texture: Texture2D = preload("res://textures/RaidTileSet.png")

var crawler_world: Node = null
var atlas_image: Image = null

func _ready() -> void:
	# Don’t block clicks
	mouse_filter = MOUSE_FILTER_IGNORE

	# Find crawler_world safely
	if crawler_world_path != NodePath():
		crawler_world = get_node_or_null(crawler_world_path)
	if crawler_world == null:
		# Fallback: assume the current scene is crawler_world
		crawler_world = get_tree().current_scene

	# Cache the atlas pixels once
	atlas_image = tile_texture.get_image()

	# Quick debug: draw a black placeholder so we know the rect works
	var dbg = Image.create(192, 192, false, Image.FORMAT_RGBA8)
	dbg.fill(Color.BLACK)
	texture_rect.texture = ImageTexture.create_from_image(dbg)

	# Positioning suggestion (top-right): anchor in the editor
	# Anchor Right: 1, Top: 0; set margins to keep it on-screen.

func _process(_delta: float) -> void:
	update_minimap()

func update_minimap() -> void:
	if crawler_world == null:
		return

	#var player_pos: Vector2i = crawler_world.get_player_grid_pos()
	var dungeon_grid = crawler_world.dungeon_grid
	if dungeon_grid.is_empty():
		return

	# Build an image for exactly the window we render (11x11 * TILE_DISPLAY_SIZE)
	var img_size := (2 * DISPLAY_GRID_SIZE + 1) * TILE_DISPLAY_SIZE
	var img := Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,1)) # undiscovered background

	for dy in range(-DISPLAY_GRID_SIZE, DISPLAY_GRID_SIZE + 1):
		for dx in range(-DISPLAY_GRID_SIZE, DISPLAY_GRID_SIZE + 1):
			var grid_x = player_pos.x + dx
			var grid_y = player_pos.y + dy

			var atlas_coords: Vector2i
			if grid_y < 0 or grid_y >= dungeon_grid.size() or grid_x < 0 or grid_x >= dungeon_grid[grid_y].size():
				# Out of bounds => empty tile (0,0)
				atlas_coords = Vector2i(0, 0)
			else:
				atlas_coords = atlas_for_cell(dungeon_grid[grid_y][grid_x], Vector2i(grid_x, grid_y), player_pos)

			# Always draw at a fixed location relative to the center
			blit_atlas_tile(img, dx + DISPLAY_GRID_SIZE, dy + DISPLAY_GRID_SIZE, atlas_coords)

	# Push to TextureRect
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	texture_rect.texture = tex

func atlas_for_cell(tile_value, grid_pos: Vector2i, player_pos: Vector2i) -> Vector2i:
	if grid_pos == player_pos:
		return ATLAS_PLAYER
	# Optional start marker if you want it: compare to crawler_world.start_room if you store it
	if crawler_world.goal_room == Vector2(grid_pos):
		return ATLAS_GOAL

	match tile_value:
		"Path":
			return ATLAS_PATH
		"Goal":
			return ATLAS_GOAL
		_:
			return ATLAS_EMPTY

func blit_atlas_tile(dst: Image, map_x: int, map_y: int, atlas_coords: Vector2i) -> void:
	if atlas_image == null:
		return

	var src_off := Vector2i(atlas_coords.x * ATLAS_TILE_SIZE, atlas_coords.y * ATLAS_TILE_SIZE)
	var dst_off := Vector2i(map_x * TILE_DISPLAY_SIZE, map_y * TILE_DISPLAY_SIZE)

	# Scale the 64x64 atlas tile down to TILE_DISPLAY_SIZE using nearest sampling
	# (manual nearest-neighbor for clarity)
	for y in range(TILE_DISPLAY_SIZE):
		for x in range(TILE_DISPLAY_SIZE):
			var sx := int(float(x) * float(ATLAS_TILE_SIZE) / float(TILE_DISPLAY_SIZE))
			var sy := int(float(y) * float(ATLAS_TILE_SIZE) / float(TILE_DISPLAY_SIZE))
			var col := atlas_image.get_pixel(src_off.x + sx, src_off.y + sy)
			dst.set_pixel(dst_off.x + x, dst_off.y + y, col)
