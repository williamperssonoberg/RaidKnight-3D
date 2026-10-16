extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	#set_cell(TILE_PARTY_POSITION, Vector2i(7, 0))
		# Ensure the overlay map starts empty
		# Get the parent node (Control) that holds both map_overlay and RaidMapTileMap
	#var parent_node = get_parent()
	#if parent_node:
	#	var map_overlay = parent_node.get_node("map_overlay")
	#	if map_overlay:
	#		map_overlay.clear()
	#		var RaidMapTileMap = parent_node.get_node("RaidMapTileMap")
	#		print("Map_overlay node cleared.")
	#		print("Map overlay position:", map_overlay.position)
	#		print("RaidMapTileMap position:", RaidMapTileMap.position)	
	#		map_overlay.set_cell(TILE_PARTY_POSITION, Vector2i(0, 0))
	#		print("Manually set cell: ", TILE_PARTY_POSITION, " at 0,0")
			#print("map_overlay cell size: ", map_overlay.cell_size)
			#print("RaidMapTileMap cell size: ", RaidMapTileMap.cell_size)
	#	else:
	#		print("Error: map_overlay node not found!")
	#else:
	#	print("Error: Parent node not found!")
		
	

	#update()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Constants for tile types
const TILE_EMPTY = 0
const TILE_WALKWAY = 1
const TILE_BOSS_ROOM = 2
const TILE_FINAL_BOSS_ROOM = 3
const TILE_ENTRANCE = 4
const TILE_PARTY_POSITION = 5

# Function to populate the TileMap
func update_raid_map(grid):
	clear()  # Clear any existing tiles
	print("Updating raid map with grid: ", grid)
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var tile_type = grid[y][x]
			# Define the source ID and atlas coordinates
			var source_id = 0  # Assuming 0 is the source ID for your TileSet
			var atlas_coords = Vector2i(0, 0)  # Default: Empty
			
			match tile_type:
				0:
					atlas_coords = Vector2i(0, 0)  # Empty
				1:
					atlas_coords = Vector2i(1, 0)  # Walkway
				2:
					atlas_coords = Vector2i(2, 0)  # Boss Room
				3:
					atlas_coords = Vector2i(3, 0)  # Final Boss Room
				4:
					atlas_coords = Vector2i(4, 0)  # Entrance
				5: 
					atlas_coords = Vector2i(5, 0)  # Party Position
			#print("Setting tile at position (", x, ",", y, ") with source_id: ", source_id, " and atlas_coords: ", atlas_coords)
			# Set the tile using source_id and atlas_coords
			set_cell(0, Vector2i(x, y), source_id, atlas_coords)


var party_tile_current_pos

func clear_party_position_tile(map_overlay):
	
	var tile_type = 5
				# Define the source ID and atlas coordinates
	var source_id = 0  # Assuming 0 is the source ID for your TileSet
	var atlas_coords = Vector2i(0, 0)  # Default: Empty
	
	match tile_type:
		0:
			atlas_coords = Vector2i(0, 0)  # Empty
		1:
			atlas_coords = Vector2i(1, 0)  # Walkway
		2:
			atlas_coords = Vector2i(2, 0)  # Boss Room
		3:
			atlas_coords = Vector2i(3, 0)  # Final Boss Room
		4:
			atlas_coords = Vector2i(4, 0)  # Entrance
		5: 
			atlas_coords = Vector2i(5, 0)  # Party Position
	
		# Clear the party position tile from the overlay map
	if party_tile_current_pos != null:
		map_overlay.set_cell(0, party_tile_current_pos)
		#print("TILE_PARTY_POSITION cleared at: ", current_pos)

# Function to toggle the party position tile
func toggle_party_position_tile(map_overlay, current_pos, is_party_tile):
	
	var tile_type = 5
				# Define the source ID and atlas coordinates
	var source_id = 0  # Assuming 0 is the source ID for your TileSet
	var atlas_coords = Vector2i(0, 0)  # Default: Empty
	
	if current_pos != party_tile_current_pos:
		clear_party_position_tile(map_overlay)
	
	party_tile_current_pos = current_pos
	
	match tile_type:
		0:
			atlas_coords = Vector2i(0, 0)  # Empty
		1:
			atlas_coords = Vector2i(1, 0)  # Walkway
		2:
			atlas_coords = Vector2i(2, 0)  # Boss Room
		3:
			atlas_coords = Vector2i(3, 0)  # Final Boss Room
		4:
			atlas_coords = Vector2i(4, 0)  # Entrance
		5: 
			atlas_coords = Vector2i(5, 0)  # Party Position
	
	if is_party_tile:
		# Set the party position tile on the overlay map
		map_overlay.set_cell(0, current_pos, 0, Vector2i(5, 0))
		#print("TILE_PARTY_POSITION set at: ", current_pos, " with tile: ", Vector2i(5, 0), "on tileset: ", map_overlay)

	else:
		if current_pos == null:
			return
			# Clear the party position tile from the overlay map
		else: 
			map_overlay.set_cell(0, current_pos)
		#print("TILE_PARTY_POSITION cleared at: ", current_pos)
