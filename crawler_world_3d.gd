extends Node3D

var GRID_WIDTH
var GRID_HEIGHT
var ROOM_SIZE := 20.0
var MONSTER_LEVEL
var DIFFICULTY
var THEME

var dungeon_grid = []
var start_room
var goal_room
var start_room_position
var walkable_cells: Array[Vector2i] = []

var player_scene = preload("res://player_3d.tscn")

@onready var dungeon_parent = $DungeonRooms
@onready var camera_rig = $CameraRig
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var player_container = $PlayerContainer  # Holds all party members
var extra_player_scene = preload("res://player/extra_player_3d.tscn")

var formation_positions_dict = {
	"slot_A1": Vector3(-10, 0, -10), "slot_A2": Vector3(-5, 0, -10), "slot_A3": Vector3(0, 0, -10), "slot_A4": Vector3(5, 0, -10), "slot_A5": Vector3(10, 0, -10),
	"slot_B1": Vector3(-10, 0, -5), "slot_B2": Vector3(-5, 0, -5), "slot_B3": Vector3(0, 0, -5), "slot_B4": Vector3(5, 0, -5), "slot_B5": Vector3(10, 0, -5),
	"slot_C1": Vector3(-10, 0, 0), "slot_C2": Vector3(-5, 0, 0), "slot_C3": Vector3(0, 0, 0), "slot_C4": Vector3(5, 0, 0), "slot_C5": Vector3(10, 0, 0),
	"slot_D1": Vector3(-10, 0, 5), "slot_D2": Vector3(-5, 0, 5), "slot_D3": Vector3(0, 0, 5), "slot_D4": Vector3(5, 0, 5), "slot_D5": Vector3(10, 0, 5),
	"slot_E1": Vector3(-10, 0, 10), "slot_E2": Vector3(-5, 0, 10), "slot_E3": Vector3(0, 0, 10), "slot_E4": Vector3(5, 0, 10), "slot_E5": Vector3(10, 0, 10)
}

var dungeon_room_scene = preload("res://dungeon_room_3d.tscn")

var params
var _party_member_ids: Array = []

func _ready():
	
	#var room = dungeon_room_scene.instantiate()
	#dungeon_parent.add_child(room)	
	#room.position = Vector3(0, 0, 0)
	
	# Get parameters from GameManager
	params = GameManager.dungeon_parameters

	# Apply dungeon parameters
	if params.is_empty():
		print("⚠ Warning: No dungeon parameters found! Using defaults.")
		params = {
			"grid_width": 10,
			"grid_height": 10,
			"room_size": 1280,
			"monster_level": 1,
			"difficulty": "easy",
			"theme": "dungeon"
		}

	# Generate the dungeon with received parameters
	generate_dungeon(params)
	add_to_group("dungeon_world")	
	camera_rig.global_position = start_room_position	

	var party_list = GameManager.selected_party
	if party_list == null:
		return	
	elif party_list.size() == 1:
		# SINGLE PLAYER MODE
		_party_member_ids.clear()
		print("Loading Single Player Mode")
		var single_player = spawn_champion(party_list[0], Vector2(0, 0))
		var champion_data = party_list[0]
		_party_member_ids.append(champion_data)
		player_container.add_child(single_player)
	
		# 🔥 Reconnect the playerdeath() signal manually
	#	if death_sound:
	#		single_player.connect("playerdeath", death_sound.play)
		
	else:
		# MULTI-CHAMPION PARTY MODE
		print("Loading Party Mode")
		load_party(party_list)


func random_spawn_position(min_dist: float = 12.0) -> Vector3:
	if walkable_cells.is_empty():
		return start_room_position

	var leader = get_tree().get_first_node_in_group("player")

	for attempt in range(20):
		var cell: Vector2i = walkable_cells.pick_random()

		var room_center := Vector3(
			(cell.x + 0.5) * ROOM_SIZE,
			0.0,
			(cell.y + 0.5) * ROOM_SIZE
		)

		var spawn_pos := room_center + Vector3(
			randf_range(-ROOM_SIZE * 0.3, ROOM_SIZE * 0.3),
			0.0,
			randf_range(-ROOM_SIZE * 0.3, ROOM_SIZE * 0.3)
		)

		if leader == null:
			return spawn_pos

		if spawn_pos.distance_to(leader.global_position) >= min_dist:
			return spawn_pos

	return start_room_position


func spawn_champion(champion_data, position):
	
	var champion_node = player_scene.instantiate()
	champion_node.add_to_group("player")
	#champion_node.setup_from_champion(champion_data)
	champion_node.position = position
	player_container.add_child(champion_node)


func generate_dungeon(params):
	GRID_WIDTH = params["grid_width"]
	GRID_HEIGHT = params["grid_height"]
	ROOM_SIZE = params["room_size"]
	MONSTER_LEVEL = params["monster_level"]
	DIFFICULTY = params["difficulty"]
	THEME = params["theme"]

	print("Generating dungeon with:", params)
	


# Step 1: Initialize an empty grid
	for y in range(GRID_HEIGHT):
		var row = []  # Create an empty row
		for x in range(GRID_WIDTH):
			row.append(null)  # Fill it with null or empty placeholders
		dungeon_grid.append(row)  # Add the row to the grid

	print("Dungeon Grid Initialized:", dungeon_grid.size(), "rows")  # Debugging


# Step 2: Select a random starting position on the grid edges
	var start_x = randi_range(0, GRID_WIDTH - 1) if randi() % 2 == 0 else (0 if randi() % 2 == 0 else GRID_WIDTH - 1)
	var start_y = randi_range(0, GRID_HEIGHT - 1) if start_x in [0, GRID_WIDTH - 1] else (0 if randi() % 2 == 0 else GRID_HEIGHT - 1)


	start_room = Vector2i(start_x, start_y)  # ✅ Ensure we have a valid Vector2
	start_room_position = Vector3((start_room.x + 0.5) * ROOM_SIZE, 0.0, (start_room.y + 0.5) * ROOM_SIZE)

	
	# ✅ Debugging Start Position
	print("Starting Room Grid Position: ", start_room)
	print("Calculated Start Position in World: ", start_room * ROOM_SIZE)
	
	# Generate the dungeon with the specified settings
	generate_dungeon_path(start_room)
	instantiate_dungeon_rooms()
	collect_walkable_cells()		
	

func generate_dungeon_path(start_pos: Vector2i):
	var visited_tiles: Array[Vector2i] = []  # Track visited rooms
	var current_pos: Vector2i = start_pos

	
	while true:
		visited_tiles.append(current_pos)
		dungeon_grid[current_pos.y][current_pos.x] = "Path"

		# Find valid moves
		var valid_moves: Array[Vector2i] = []
		for dir in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]:  # Left, Right, Down, Up
			var new_pos: Vector2i = current_pos + dir
			
			# Skip out-of-bounds moves
			if new_pos.x < 0 or new_pos.x >= GRID_WIDTH or new_pos.y < 0 or new_pos.y >= GRID_HEIGHT:
				continue
			
			# Skip already visited rooms
			if new_pos in visited_tiles:
				continue
			
			valid_moves.append(new_pos)

		# If valid moves exist, continue path
		if valid_moves.size() > 0:
			current_pos = valid_moves[randi() % valid_moves.size()]  # Randomly select a valid move
		else:
			break  # No valid moves left, terminate path generation

	# Set the final room in the path as the goal room
	if visited_tiles.size() > 0:
		goal_room = visited_tiles[-1]
		dungeon_grid[goal_room.y][goal_room.x] = "Goal"
	

		
		
func instantiate_dungeon_rooms():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if dungeon_grid[y][x] == "Path" or dungeon_grid[y][x] == "Goal":
				var room_instance = dungeon_room_scene.instantiate()
				room_instance.position = Vector3((x + 0.5) * ROOM_SIZE, 0.0, (y + 0.5) * ROOM_SIZE)

# Setup walls: open where neighbor exists
				var neigh = neighbors_for(x, y)
				if room_instance.has_method("setup_walls"):
					room_instance.setup_walls(neigh)


				# ✅ Debug Output to Confirm Room Creation
				print("Placing Room at: ", room_instance.position, " (Grid:", x, ",", y, ")")

				# ✅ Check if room has Sprite2D
				#if room_instance.has_node("Sprite2D"):
				#	print("✅ Room has a Sprite2D")
				#else:
				#	print("❌ ERROR: Room does NOT have Sprite2D!")

				# ✅ Mark goal rooms
			#	if dungeon_grid[y][x] == "Goal":
			#		room_instance.set_as_goal()
			#		print("✅ Goal Room Created at:", room_instance.position, " (Grid:", x, ",", y, ")")
				
				#Name room
				room_instance.name = "DungeonRoom_" + str(x) + "_" + str(y)
				# ✅ Add to the world scene
				dungeon_parent.add_child(room_instance)


func is_walkable_cell(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= GRID_WIDTH or y >= GRID_HEIGHT:
		return false
	var v = dungeon_grid[y][x]
	return v == "Path" or v == "Goal"

func collect_walkable_cells():
	walkable_cells.clear()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if is_walkable_cell(x, y):
				walkable_cells.append(Vector2i(x, y))
	print("Walkable cells: ", walkable_cells)

func neighbors_for(x: int, y: int) -> Dictionary:
	return {
		"left":  is_walkable_cell(x - 1, y),
		"right": is_walkable_cell(x + 1, y),
		"up":    is_walkable_cell(x, y - 1),
		"down":  is_walkable_cell(x, y + 1),
	}

func spawn_test_leader():
	var player = player_scene.instantiate()
	$PlayerContainer.add_child(player)

	player.global_position = Vector3(
		start_room_position.x,
		1.0,
		start_room_position.z
	)

	player.add_to_group("party_leader")

	print("Spawned test leader at: ", player.global_position)

func spawn_leader(champion_data, position):
	var leader_node = player_scene.instantiate()
	$PlayerContainer.add_child(leader_node)
	if leader_node == null:
		print("Error: Could not instantiate player scene!")
		return null  # Prevent crashes if the scene is missing
	leader_node.global_position = Vector3(
		start_room_position.x,
		0,
		start_room_position.z
	)

	leader_node.add_to_group("party_leader")  # Ensure it's in the player group	
	player_container.add_child(leader_node)
	leader_node.position = position

	print("Leader added:", champion_data.champion_name, "at", position)

	return leader_node

	
func load_party(party_list):
	if party_list.is_empty():
		print("Error: No champions in party!")
		return
		
	print("Loading Party Mode with ", party_list.size(), " champions.")
		
	var leader = null  # Track the leader node
	_party_member_ids.clear()
	for i in range(party_list.size()):
		var champion_data = party_list[i]
		var slot_name = GameManager.formation_positions[i] if i < GameManager.formation_positions.size() else "C3"  # Default to C3 if missing
		var position_offset = formation_positions_dict.get(slot_name, Vector3.ZERO)  # Convert slot to Vector2 position
			#
	#if party_list:
	#	for member in party_list:
		_party_member_ids.append(champion_data)
		print("Spawning Champion: ", champion_data.champion_name, " at ", slot_name, " -> ", position_offset)

		if i == 0:
			# First champion is the leader (player.tscn)
			leader = spawn_leader(champion_data, position_offset)
			leader.set_starting_position(start_room_position)
			
				# 🛑 Debug: Check if leader exists
			if leader == null:
				print("Error: Leader failed to instantiate!")
				return

			
			await get_tree().process_frame		
			leader.setup_from_champion(champion_data)
		else:
			# Other champions are extra_player.tscn
			var follower = spawn_follower(champion_data, position_offset)

			await get_tree().process_frame		
			follower.setup_from_champion(champion_data)		
			if leader:
				follower.reparent(leader)  # Attach followers to leader

	print("All party members added and positioned.")

func get_leader() -> Node3D:
	var leader := get_tree().get_first_node_in_group("party_leader")
	return leader as Node3D

func spawn_follower(champion_data, position):
	
	var follower_node = extra_player_scene.instantiate()
	follower_node.add_to_group("player")

	# Followers start near the leader
	follower_node.global_position = start_room_position + position
	
	
	# Set follow target and offset
	var leader = get_leader()  # however you store the leader
	if leader:
		var rotated_offset = position.rotated(Vector3.UP, leader.rotation.y)

		follower_node.global_position = leader.global_position - rotated_offset 
		follower_node.follow_target = leader
		follower_node.rotation.y = leader.rotation.y
		#follower_node.follow_offset = position  # same as the formation offset
		

	#follower_node.position = position + start_room_position
	player_container.add_child(follower_node)
	print("Party Champion added:", champion_data.champion_name, " at ", position)

	return follower_node

func _process(_delta):
	var leader = get_tree().get_first_node_in_group("party_leader")

	if leader:
		camera_rig.global_position = leader.global_position
