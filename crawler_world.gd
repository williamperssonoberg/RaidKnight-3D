extends Node2D

@onready var player_container = $PlayerContainer  # Holds all party members
@onready var death_sound = $snd_Music  # Adjust to the actual sound node path

var party_positions = [  # 5 predefined positions (modify later for 5x5)
	Vector2(0, 0),    # Center (Leader)
	Vector2(-50, -30),  # Front Left
	Vector2(50, -30),   # Front Right
	Vector2(-50, 30),   # Back Left
	Vector2(50, 30)     # Back Right
]

var minimap_data = []  # Stores if each tile is explored
var minimap = null
@onready var pause_menu := $HUD/CW_PauseMenu
@onready var guildinventory = %InventoryPanel
@onready var championPanel = %ChampionPanel

# temp inventory for this run
var dungeon_inventory: Array = []  # each element is your item data (dict/object)
var dungeon_inventory_capacity := 0

signal player_room_changed(new_room: Vector2i)

var _last_player_grid := Vector2i(-999, -999) # for change detection
var _registered_minimap: Node = null
var walkable_cells: Array[Vector2i] = []

func collect_walkable_cells():
	walkable_cells.clear()
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if is_walkable_cell(x, y):
				walkable_cells.append(Vector2i(x, y))
	print("Walkable cells: ", walkable_cells)

# Optional: so the minimap can register itself if you want to push updates to it
func register_minimap(node: Node) -> void:
	_registered_minimap = node


# Returns the leader (main controllable player). We already add them to the "player" group in spawn_leader().
func get_leader() -> Node2D:
	var leader := get_tree().get_first_node_in_group("player")
	return leader as Node2D


# Convert the leader's current world position into grid coords.
# Assumes rooms are instanced at (x * ROOM_SIZE, y * ROOM_SIZE) like you do in instantiate_dungeon_rooms().
func get_player_grid_pos() -> Vector2i:
	var leader := get_leader()
	if leader == null:
		return Vector2i(-1, -1)

	# Position of the player in the dungeon's local/world frame:
	# If the world (DungeonRooms) moves and the player stays centered,
	# this still gives the correct "virtual world" position.
	var pos_in_dungeon_space: Vector2 = (leader.global_position - dungeon_parent.global_position)
	
	#pos_in_dungeon_space -= Vector2(ROOM_SIZE * 0.5, ROOM_SIZE * 0.5)
	
	if ROOM_SIZE == 0:
		return Vector2i(-1, -1)

	var gx := int(floor(pos_in_dungeon_space.x / float(ROOM_SIZE)))
	var gy := int(floor(pos_in_dungeon_space.y / float(ROOM_SIZE)))

	gx = clamp(gx, 0, GRID_WIDTH - 1)
	gy = clamp(gy, 0, GRID_HEIGHT - 1)
	return Vector2i(gx, gy)


# (Optional) If you want the world to notify the minimap only when the player enters a new room:
func _physics_process(_delta: float) -> void:
	var cur := get_player_grid_pos()
	if cur != _last_player_grid and cur.x >= 0:
		_last_player_grid = cur
		emit_signal("player_room_changed", cur)
		# If your minimap registered itself, you could also call a method on it:
		if _registered_minimap and _registered_minimap.has_method("on_player_room_changed"):
			_registered_minimap.on_player_room_changed(cur)



var formation_positions_dict = {
	"slot_A1": Vector2(-100, -100), "slot_A2": Vector2(-50, -100), "slot_A3": Vector2(0, -100), "slot_A4": Vector2(50, -100), "slot_A5": Vector2(100, -100),
	"slot_B1": Vector2(-100, -50), "slot_B2": Vector2(-50, -50), "slot_B3": Vector2(0, -50), "slot_B4": Vector2(50, -50), "slot_B5": Vector2(100, -50),
	"slot_C1": Vector2(-100, 0), "slot_C2": Vector2(-50, 0), "slot_C3": Vector2(0, 0), "slot_C4": Vector2(50, 0), "slot_C5": Vector2(100, 0),
	"slot_D1": Vector2(-100, 50), "slot_D2": Vector2(-50, 50), "slot_D3": Vector2(0, 50), "slot_D4": Vector2(50, 50), "slot_D5": Vector2(100, 50),
	"slot_E1": Vector2(-100, 100), "slot_E2": Vector2(-50, 100), "slot_E3": Vector2(0, 100), "slot_E4": Vector2(50, 100), "slot_E5": Vector2(100, 100)
}

var player_scene = preload("res://player/player.tscn")
var extra_player_scene = preload("res://player/extra_player.tscn")
var _party_member_ids: Array = []
var params

func _ready():
	
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
	
	var selected_champion = GameManager.selected_champion
	if selected_champion:
		# SINGLE PLAYER MODE
		print("Loading Single Player Mode")
		var single_player = spawn_champion(selected_champion, Vector2(0, 0))
		player_container.add_child(single_player)		
		await get_tree().process_frame	
		single_player.setup_from_champion(selected_champion)
		
			# 🔥 Reconnect the playerdeath() signal manually
		if death_sound:
			single_player.connect("playerdeath", death_sound.play)
		return
		
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
		if death_sound:
			single_player.connect("playerdeath", death_sound.play)
		
	else:
		# MULTI-CHAMPION PARTY MODE
		print("Loading Party Mode")
		load_party(party_list)
	# ✅ Ensure we only connect to the correct GoalFlag (from the goal room)
	
	print("🔎 Printing scene tree to find DungeonRooms:")
	print_tree_pretty()
	
	if goal_room:
		print("🔎 Expected Goal Room Coordinates: ", goal_room)
		var gx = int(goal_room.x)
		var gy = int(goal_room.y)
		var goal_dungeon_room_path = "DungeonRooms/DungeonRoom_%s_%s" % [gx, gy]
		print("🔎 Checking for node at path: ", goal_dungeon_room_path)
		
		if has_node(goal_dungeon_room_path):
			var goal_dungeon_room = get_node(goal_dungeon_room_path)
			print("✅ Found goal room:", goal_dungeon_room)
			
			var goal_flag = goal_dungeon_room.get_node("GoalFlag") if goal_dungeon_room.has_node("GoalFlag") else null
			if goal_flag:
				goal_flag.connect("dungeon_completed", Callable(self, "_on_dungeon_complete"))
				print("✅ GoalFlag connected successfully!")
			else:
				print("❌ ERROR: GoalFlag node not found in goal room!")
		
		var goal_dungeon_room = get_node(goal_dungeon_room_path) if has_node(goal_dungeon_room_path) else null

		if goal_dungeon_room:
			var goal_flag = goal_dungeon_room.get_node("GoalFlag")
			if goal_flag:
				goal_flag.connect("dungeon_completed", Callable(self, "_on_dungeon_complete"))
				print("✅ GoalFlag connected successfully!")
			else:
				print("❌ ERROR: GoalFlag node not found in goal room!")
		else:
			print("❌ ERROR: Goal room node not found! Path might be incorrect.")
	
	# capacity: 5 per party member
	var size := 0

	if party_list:
		size = party_list.size()
	dungeon_inventory_capacity = size * 5

func _unhandled_input(event):
	if event.is_action_pressed("pause_game"):
		toggle_pause()

func toggle_pause():
	var paused = get_tree().paused
	if paused:
		get_tree().paused = false
		pause_menu.hide()
	if victory_condition:
		pause_menu.populate_victory(self)
		pause_menu.show()
		guildinventory.connect("update_champion_panel", Callable(self, "open_champion_panel"))
		get_tree().paused = true
	else:
		# update party + inventory UI before showing
		pause_menu.populate(self)
		pause_menu.show()
		guildinventory.connect("update_champion_panel", Callable(self, "open_champion_panel"))
		get_tree().paused = true

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
		var position_offset = formation_positions_dict.get(slot_name, Vector2.ZERO)  # Convert slot to Vector2 position
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

func spawn_champion(champion_data, position):
	
	var champion_node = player_scene.instantiate()
	champion_node.add_to_group("player")
	#champion_node.setup_from_champion(champion_data)
	champion_node.position = position
	player_container.add_child(champion_node)

	# Ensure the main player is in the "player" group
	#if player_container.get_child_count() == 1:  # The first spawned champion is the leader
			
	
	return champion_node

func spawn_leader(champion_data, position):
	var leader_node = player_scene.instantiate()
	if leader_node == null:
		print("Error: Could not instantiate player scene!")
		return null  # Prevent crashes if the scene is missing

	leader_node.add_to_group("player")  # Ensure it's in the player group	
	player_container.add_child(leader_node)
	leader_node.position = position

	print("Leader added:", champion_data.champion_name, "at", position)

	return leader_node


func spawn_follower(champion_data, position):
	
	var follower_node = extra_player_scene.instantiate()
	follower_node.add_to_group("player")

	# Followers start near the leader
	follower_node.global_position = start_room_position + position
	
	
	# Set follow target and offset
	var leader = get_leader()  # however you store the leader
	if leader:
		follower_node.follow_target = leader
		follower_node.follow_offset = position  # same as the formation offset

	#follower_node.position = position + start_room_position
	player_container.add_child(follower_node)
	print("Party Champion added:", champion_data.champion_name, " at ", position)

	return follower_node


#------------------------ DUNGEON TIME

var GRID_WIDTH
var GRID_HEIGHT
var ROOM_SIZE  # Room dimensions (1280x1280 pixels)
var MONSTER_LEVEL
var DIFFICULTY
var THEME

var dungeon_grid = []  # 2D array to store the dungeon layout
var start_room = null
var goal_room = null

@onready var dungeon_parent = $DungeonRooms  # Node to hold all generated rooms

var dungeon_room_scene = preload("res://dungeon_room.tscn")  # Load room scene
var start_room_position = Vector2.ZERO  # Default in case of errors

func init_minimap_data():
	minimap_data.resize(GRID_HEIGHT)
	for y in range(GRID_HEIGHT):
		minimap_data[y] = []
		for x in range(GRID_WIDTH):
			minimap_data[y].append(false)  # Not explored yet


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


	start_room = Vector2(start_x, start_y)  # ✅ Ensure we have a valid Vector2
	start_room_position = Vector2((start_room.x + 0.5) * ROOM_SIZE, (start_room.y + 0.5) * ROOM_SIZE)

	
	# ✅ Debugging Start Position
	print("Starting Room Grid Position: ", start_room)
	print("Calculated Start Position in World: ", start_room * ROOM_SIZE)
	
	# Generate the dungeon with the specified settings
	generate_dungeon_path(start_room)
	instantiate_dungeon_rooms()
	collect_walkable_cells()	
	
	
func generate_dungeon_path(start_pos):
	var visited_tiles = []  # Track visited rooms
	var current_pos = start_pos

	
	while true:
		visited_tiles.append(current_pos)
		dungeon_grid[current_pos.y][current_pos.x] = "Path"

		# Find valid moves
		var valid_moves = []
		for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]:  # Left, Right, Down, Up
			var new_pos = current_pos + dir
			
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
				room_instance.position = Vector2((x + 0.5) * ROOM_SIZE, (y + 0.5) * ROOM_SIZE)

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
				if dungeon_grid[y][x] == "Goal":
					room_instance.set_as_goal()
					print("✅ Goal Room Created at:", room_instance.position, " (Grid:", x, ",", y, ")")
				
				#Name room
				room_instance.name = "DungeonRoom_" + str(x) + "_" + str(y)
				# ✅ Add to the world scene
				dungeon_parent.add_child(room_instance)


func print_dungeon_grid():
	for row in dungeon_grid:
		print("printing rows in dungeon grid: ", row)

var victory_condition = false

func _on_dungeon_complete():
	victory_condition = true
	
	var level := int(MONSTER_LEVEL) # or GameManager.dungeon_parameters.get("monster_level", 1)
	var victory_xp := get_victory_xp_for_level(level)
	distribute_xp_to_party(victory_xp)
	print("The party members received ", victory_xp / _party_member_ids.size(), " XP each for completing the dungeon!")
	print("🏆 Dungeon Completed! Returning to City...")
	toggle_pause()

	# Example: Change Scene or Show Victory UI
	#var player = get_tree().get_first_node_in_group("player")
	#if player:
	#	player._on_dungeon_completed_panel()
	#else:
	#	print("❌ Player not found to trigger dungeon complete.")
	# Decide what to do with remaining dungeon_inventory (drop them)
	#dungeon_inventory.clear()
	# Go back to city / show victory UI as you already do
	# change scene or open city panel
		
# Called by enemy signal
func _on_enemy_defeated(xp:int) -> void:
	distribute_xp_to_party(xp)

var victory_xp_values = [
	400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500,
	7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300,
	23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44100,
	46800, 49600, 52500, 55500, 58600, 61700, 64900, 68200, 71600, 75100,
	78700, 82400, 86100, 90000, 94000, 98100, 102300, 106600, 111000, 115500,
	120100, 124800, 129600, 134500, 139500, 144600, 149800, 155100, 160500, 166000,
	171600, 177300, 183100, 189000, 195000, 201000, 207100, 213300, 219600
]

func get_victory_xp_for_level(level: int) -> int:
	if victory_xp_values.is_empty():
		return 0
	# Map level 1 -> index 0, level 20 -> index 19, etc. Clamp to array size.
	var idx: int = clamp(level, 1, victory_xp_values.size()) - 1
	return int(victory_xp_values[idx])

func distribute_xp_to_party(total_xp:int) -> void:
	if _party_member_ids.is_empty():
		return

	var n := _party_member_ids.size()
	var share := int(max(1, floor(total_xp / float(n))))

	for champion in _party_member_ids:
		# Preferred: update via GameManager by ID

		GlobalData.add_xp_to_champion(champion, share)
		print(champion.champion_name, " gained ", share, " XP!")

func open_guild_inventory():
		guildinventory.show()
		pass

func open_champion_panel(champion):
	# Open your existing champion panel UI with this champion selected
	%ChampionPanel.open(champion)
	pass

signal item_info_message(msg: String)
	
func equip_item_from_dungeon_slot(slot_index: int, champion):
	print("Called equip item from dungeon slot")
	if slot_index < 0 or slot_index >= dungeon_inventory.size():
		return
	var selected_item = dungeon_inventory[slot_index]

	if selected_item == null or champion == null:
		if pause_menu:
			item_info_message.emit("Please select an item and a champion.")
			print("no item or champion selected")
		return


	# Validate level
	if selected_item.required_level > champion.champion_xp_level:
		if pause_menu:
			item_info_message.emit("%s requires level %d. %s is only level %d.")
			print("champion is doesn't meet the level req")
#			pause_menu.item_description.text = "%s requires level %d. %s is only level %d." % [
#				selected_item.item_name,
#				selected_item.required_level,
#				champion.champion_xp_level,
#				champion.champion_name
#			]
		return

	# Equip item (calls use_item func)
	if selected_item.use_item.is_valid():
		selected_item.use_item.call(champion, selected_item)
		if pause_menu:
			item_info_message.emit("Equipped %s on %s" % [selected_item.item_name, champion.champion_name])
			championPanel.open(champion)
			champion.recalc_combat_stats()
			print("CHAMP: ", champion.champion_name, " ilvl: ", champion.champion_item_level, " str: ", champion.champion_strength, " power: ", champion.calculate_champion_power())

	else:
		if pause_menu:
			pause_menu.item_description.text = "Error: Item use function invalid."
		return



	# If successful:
	dungeon_inventory.remove_at(slot_index)



func send_item_to_guild_from_slot(slot_index: int):
	print("Called send item to guild from slot")
	if slot_index < 0 or slot_index >= dungeon_inventory.size():
		return
	var item = dungeon_inventory[slot_index]
	if item == null:
		return

	# Add to global guild inventory

	GlobalData.add_item_to_global_inventory(item)
	guildinventory.populate_inventory_from_global()
	dungeon_inventory.remove_at(slot_index)

func drop_item_from_slot(slot_index: int):
	if slot_index < 0 or slot_index >= dungeon_inventory.size():
		return
	dungeon_inventory.remove_at(slot_index)
	
func try_add_item_to_dungeon_inventory(item) -> bool:
	if dungeon_inventory.size() >= dungeon_inventory_capacity:
		return false
	dungeon_inventory.append(item)
	return true

func is_walkable_cell(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= GRID_WIDTH or y >= GRID_HEIGHT:
		return false
	var v = dungeon_grid[y][x]
	return v == "Path" or v == "Goal"
	
func is_walkable_world_pos(pos: Vector2) -> bool:
	if ROOM_SIZE <= 0:
		return false

	var gx := int(floor(pos.x / float(ROOM_SIZE)))
	var gy := int(floor(pos.y / float(ROOM_SIZE)))

	if gx < 0 or gy < 0 or gx >= GRID_WIDTH or gy >= GRID_HEIGHT:
		return false

	return is_walkable_cell(gx, gy)

func neighbors_for(x: int, y: int) -> Dictionary:
	return {
		"left":  is_walkable_cell(x - 1, y),
		"right": is_walkable_cell(x + 1, y),
		"up":    is_walkable_cell(x, y - 1),
		"down":  is_walkable_cell(x, y + 1),
	}

func random_spawn_position(min_dist_px: float = 800.0) -> Vector2:
	if walkable_cells.is_empty():
		return start_room_position

	var leader := get_leader()
	var leader_pos = Vector2(leader.global_position) if leader else start_room_position

	var best_pos: Vector2 = leader_pos
	var best_dist: float = -1.0

	var tries := 30
	while tries > 0:
		var cell: Vector2i = walkable_cells[randi() % walkable_cells.size()]
		#var base = Vector2(cell.x, cell.y) * ROOM_SIZE
		# ✅ treat each room origin as its CENTER
		var origin = dungeon_parent.global_position
		var room_center = Vector2((cell.x + 0.5) * ROOM_SIZE, (cell.y + 0.5) * ROOM_SIZE)
		print("dungeon_parent global:", dungeon_parent.global_position)
		# pick random point inside room, away from edges
		#var pos = base + Vector2(
		#	ROOM_SIZE * 0.2 + randf() * ROOM_SIZE * 0.6,
		#	ROOM_SIZE * 0.2 + randf() * ROOM_SIZE * 0.6
		#)
		# pick random point inside room, away from edges
		var pos = room_center + Vector2(
			(randf() - 0.5) * ROOM_SIZE * 0.6,
			(randf() - 0.5) * ROOM_SIZE * 0.6
		)
		
		var d := leader_pos.distance_to(pos)

		# if far enough, use it immediately
		if d >= min_dist_px:
			return pos

		# otherwise remember the farthest we've seen
		if d > best_dist:
			best_dist = d
			best_pos = pos

		tries -= 1
		print("SPAWN cell = ", cell, " rooom center = ", room_center , " pos = ", pos, " ROOM_SIZE = ", ROOM_SIZE)
	
	# No point was >= min_dist_px, so use the farthest valid one we found
	return best_pos
