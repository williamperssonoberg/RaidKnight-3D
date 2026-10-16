extends Node2D

var guild_roster = [] # List to store champions in the guild roster
var champion_ui_container
var champion_details_container
var active_raid_party_container
var raid_party_container
var roster_list # Reference to UI element displaying the guild roster
var selected_champion # Declare a variable to store the currently selected champion
var selected_dungeon = "Idle"  # Variable to store the currently selected dungeon
#var GlobalData
var MAX_PARTY_SIZE = 40
var raid_party = [] #list to store dungeon party
var raid_dropdown
var raid_party_details_container
var raid_info_container
var raid_buttons = [] # Array to store the raid buttons for easy reference
var active_raid_parties = []
var dps_container_1 = {"node": null, "role": Role.DPS}
var dps_container_2 = {"node": null, "role": Role.DPS}
var dps_container_3 = {"node": null, "role": Role.DPS}
var tank_container = {"node": null, "role": Role.TANK}
var healer_container = {"node": null, "role": Role.HEALER}
var raid_power = 500  # Example dungeon power value
var party_timers = {}  # Dictionary to store references to buttons
# Enum to represent roles
enum Role { TANK, HEALER, DPS }
var champion_data_node
var map_update_timer = Timer.new()
var is_party_tile = true
const GRID_WIDTH = 15
const GRID_HEIGHT = 30

var selected_raid

var raid_list = []  # List to store generated raids
@onready var generated_raid_container # Reference to the container for raid buttons

var chat_panel_scene = preload("res://ChatPanel.tscn")
# Called when the node enters the scene tree for the first time.

#double click tracker
var last_click_time = 0.0
const DOUBLE_CLICK_INTERVAL = 0.3  # Max time (in seconds) between clicks to register as double-click



func _ready():
	print("Raid Play scene ready!")
	# Assuming '0' is the Source ID for your tilesheet in the TileSet
	#var source_id = 0  # The source ID of the tilesheet
	#var atlas_coords = Vector2i(4, 0)  # Fifth tile in the top row (0-indexed)
	#$CanvasLayer/Control/map_overlay.set_cell(0, Vector2i(0, 0), 0, Vector2i(5, 0))
	#print("Tile set using atlas coordinates: ", atlas_coords, " at position (0, 0)")
	#global_data_node = get_node("/root/GlobalData")
	var chat_panel = chat_panel_scene.instantiate()  # Create an instance of the scene
	add_child(chat_panel)  # Add the instance to the scene tree

	raid_party_details_container = get_node("CanvasLayer/Control/RaidPartyDetailsContainer")
	champion_ui_container = get_node("CanvasLayer/Control/ChampionUIContainer")
	champion_details_container = get_node("CanvasLayer/Control/ChampionDetailsContainer")
	roster_list = get_node("CanvasLayer/Control/GuildRosterContainer")
	raid_party_container = get_node("CanvasLayer/Control/RaidPartyContainer")
	active_raid_party_container = get_node("CanvasLayer/Control/ActiveRaidPartyContainer")
	generated_raid_container = get_node("CanvasLayer/Control/GeneratedRaidScrollContainer/GeneratedRaidContainer")
	print("Party Timer type:", typeof(party_timers))
	raid_info_container = get_node("CanvasLayer/Control/RaidMapTileMap/RaidInfoContainer")
	
		# Clear the container first
	clear_container_children(active_raid_party_container)
	show_global_roster_list()
	
	raid_dropdown = get_node("CanvasLayer/Control/RaidOptions")
	# List of activity options
	var raid_options = ["Idle", "Raid 1", "Raid 2", "Raid 3", "Raid 4", "Raid 5", "Raid 6"]
	# Add activity options to the dropdown menu
	add_raid_options(raid_options)
	
		# Load existing generated raids from global data
	for raid_data in GlobalData.generated_raids:
		add_raid_to_list(raid_data.name)
	
	for raid_party_name in GlobalData.raid_parties.keys():
		update_raid_button_text(raid_party_name)	

		# Register this scene with GlobalData
	GlobalData.raid_play_scene_ref = self
	
		# Set up a timer to periodically update the buttons
	var timer = Timer.new()
	timer.name = "Timer"  # Give the timer a name to easily reference it later
	timer.set_wait_time(1.0)
	timer.set_one_shot(false)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()
	

	map_update_timer.name = "Map Update Timer"  # Give the timer a name to easily reference it later
	map_update_timer.set_wait_time(0.5)
	map_update_timer.set_one_shot(false)
	map_update_timer.connect("timeout", Callable(self, "_on_map_update_timer_timeout"))
	add_child(map_update_timer)
	map_update_timer.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_champion_details(champion):
	
		# Calculate skill label based on skill value
	var skill_label: String
	if champion.champion_skill >= 1 and champion.champion_skill <= 25:
		skill_label = "Noob"
	elif champion.champion_skill >= 26 and champion.champion_skill <= 69:
		skill_label = "Casual"
	elif champion.champion_skill >= 70 and champion.champion_skill <= 94:
		skill_label = "Raider"
	elif champion.champion_skill >= 95 and champion.champion_skill <= 99:
		skill_label = "Hardcore"
	else:
		skill_label = "Pro Gamer"
	
	# Assuming ChampionDetailsContainer has labels named "lblName" and "lblUniqueId"
	var lbl_name = champion_details_container.get_node("lblName")
	var lbl_class = champion_details_container.get_node("lblClass")
	var lbl_spec = champion_details_container.get_node("lblSpec")
	var lbl_skill = champion_details_container.get_node("lblSkill")
	var lbl_race = champion_details_container.get_node("lblRace")
	var lbl_level = champion_details_container.get_node("lblLevel")
	var lbl_champion_power = champion_details_container.get_node("lblChampionPower")
	var lbl_status = champion_details_container.get_node("lblStatus")

	lbl_name.text = "Name: " + champion.champion_name
	lbl_class.text = "Class: " + champion.champion_class
	lbl_spec.text = "Spec: " + champion.champion_specialization
	lbl_skill.text = "Skill level: " + str(champion.champion_skill) + " (" + skill_label + ")"
	lbl_race.text = "Race: " + champion.champion_race
	lbl_level.text = "Level: " + str(champion.champion_xp_level)
	lbl_champion_power.text = "Power: " + str(champion.champion_power)
	lbl_status.text = "Status: " + champion.champion_status

func show_global_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	print("Show global roster list function called")

	# Retrieve guild roster data from the global script
	guild_roster = GlobalData.get_guild_roster()
	
	#print(guild_roster)	

	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = champion.create_champion_button(champion)
	#	champion_roster_button.text = champion.champion_name
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion, champion_roster_button))
		
	
		
		roster_list.add_child(champion_roster_button)

func clear_container_children(container):
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
		
func _on_champion_button_pressed(champion, button):
	var current_time = Time.get_ticks_msec() / 1000.0  # Get current time in seconds
	if current_time - last_click_time < DOUBLE_CLICK_INTERVAL:
		_on_champion_button_double_clicked(champion, button)  # Call double-click function
	else:
		_on_champion_button_single_clicked(champion, button)  # Fallback to single click if not double-click
		
	last_click_time = current_time  # Update the last click time
			
		
		
func _on_champion_button_single_clicked(champion, button):
	# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	update_champion_details(champion)
	selected_champion = champion
	#_on_character_drag_start(button)
	
func _on_champion_button_double_clicked(champion, button):
		# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	update_champion_details(champion)
	selected_champion = champion	
	
		 # Check if the champion already exists in the party
	if raid_party.size() < MAX_PARTY_SIZE:
		
		if raid_party.find(champion) == -1:
		# If the champion doesn't exist, add it to the party
			raid_party.append(champion)
			print("Added " + champion.champion_name + " to party.")
			update_raid_party_list()
		else:
				# If the champion exists, remove it from the party
			raid_party.erase(champion)
	else:
		print("Maximum raid party size reached. Cannot add more champions.")	
	
		# Check if the champion exists in the party
	#if raid_party.find(champion) != -1:
	#if index 
		# If the champion exists, remove it from the party
	#	raid_party.erase(champion)
		
	update_raid_party_list()

# Function to update the roster list UI element
func update_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	
	#GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = champion.create_champion_button(champion)
		#champion_roster_button.text = champion.champion_name

		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion, champion_roster_button))
		
				# Set background color based on champion's class
		
		roster_list.add_child(champion_roster_button)

		


func remove_from_party(champion):

	# Check if the champion exists in the party
	if raid_party.find(champion) != -1:
	#if index 
		# If the champion exists, remove it from the party
		raid_party.erase(champion)
		
	update_raid_party_list()
	#else:
	#	print("Champion is not in the party!")
		

func add_to_party(champion):

	if champion.champion_status != "Idle":
		print("Champion ", champion.champion_name, " is busy. Status: ", champion.champion_status )
		return
	 # Check if the champion already exists in the party
	if raid_party.size() < MAX_PARTY_SIZE:
		
		if raid_party.find(champion) == -1:
		# If the champion doesn't exist, add it to the party
			raid_party.append(champion)
			print("Added " + champion.champion_name + " to party.")
			update_raid_party_list()
		else:
			pass
	else:
		print("Maximum raid party size reached. Cannot add more champions.")	
	
	#else:
	#	print("Champion is arlready in the party!")

func update_raid_party_details_list():
	 # Clear the list content
	clear_container_children(raid_party_details_container)
	var num_tanks = 0
	var num_healers = 0
	var num_dps = 0	
	var combined_power = 0
			
	for champion in raid_party:
		
		champion.calculate_champion_power()
		
		# Calculate the champion's power with potential skillful skill bonus
		var base_power = champion.champion_power
		var adjusted_power = base_power	
		
				# Check if the champion has a skillful skill and adjust power accordingly
		if champion.skillful_skill:
			match champion.skillful_skill:
				"Skillful_Healer":
					if champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
						adjusted_power *= 1.05
						var skillful_healer_label = Label.new()
						skillful_healer_label.text = champion.champion_name + " is skillful Healer! 5% bonus power"
						raid_party_details_container.add_child(skillful_healer_label)
				"Skillful_Tank":
					if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
						adjusted_power *= 1.05
						var skillful_tank_label = Label.new()
						skillful_tank_label.text = champion.champion_name + " is skillful Tank! 5% bonus power"
						raid_party_details_container.add_child(skillful_tank_label)
				"Skillful_Melee_DPS":
					if champion.champion_specialization in ["Berserker", "Stalker", "Wind"]:
						adjusted_power *= 1.05
						var skillful_melee_label = Label.new()
						skillful_melee_label.text = champion.champion_name + " is skillful Melee DPS! 5% bonus power"
						raid_party_details_container.add_child(skillful_melee_label)
				"Skillful_Ranged_DPS":
					if champion.champion_specialization in ["Voodoo", "Fire", "Necromancer"]:
						adjusted_power *= 1.05
						var skillful_ranged_label = Label.new()
						skillful_ranged_label.text = champion.champion_name + " is skillful Ranged DPS! 5% bonus power"
						raid_party_details_container.add_child(skillful_ranged_label)
				"None":
					pass
			
		# Check if the champion is a tank
		if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
			num_tanks += 1

		# Check if the champion is a healer
		elif champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
			num_healers += 1

		# Check if the champion is a DPS (either ranged or melee)
		elif champion.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Necromancer", "Stalker"]:
			num_dps += 1
				
		# Ensure adjusted_power is valid
		if adjusted_power == null:
			adjusted_power = base_power

		# Add the adjusted power to the combined power
		combined_power += adjusted_power
		
		print(champion.champion_name, "base power:", base_power, "adjusted power:", adjusted_power)

	
	var raid_party_combined_power_label = Label.new()
	raid_party_combined_power_label.text = "Total party power is " + str(combined_power)
	raid_party_details_container.add_child(raid_party_combined_power_label)
	
	var raid_party_tanks_label = Label.new()
	raid_party_tanks_label.text = "Tanks: " + str(num_tanks)
	raid_party_details_container.add_child(raid_party_tanks_label)
	
	var raid_party_healers_label = Label.new()
	raid_party_healers_label.text = "Healers: " + str(num_healers)
	raid_party_details_container.add_child(raid_party_healers_label)
	
	var raid_party_dps_label = Label.new()
	raid_party_dps_label.text = "DPS: " + str(num_dps)
	raid_party_details_container.add_child(raid_party_dps_label)		
		
	var raid_dropdown = get_node("CanvasLayer/Control/RaidOptions")
	var selected_raid_index = raid_dropdown.selected
	
	

	if selected_dungeon == "Idle":
		return  # No dungeon selected
		
	var raid_name = selected_dungeon
	var raid_data = GlobalData.get_raid_data(raid_name)	
	if raid_data.has(selected_raid):
		var data = raid_data[selected_raid]
		var selected_raid = raid_dropdown.get_item_text(selected_raid_index)	
		var raid_power = data["raid_power"]
		var success_chance = float(combined_power) / raid_power
		var raid_party_success_label = Label.new()
		raid_party_success_label.text = "Success chance: " + str(success_chance)
		raid_party_details_container.add_child(raid_party_success_label)

func update_raid_party_list():
	 # Clear the list content
	clear_container_children(raid_party_container)

	
	#global_data_node.set_guild_roster(guild_roster)
	
	# Add champions in the dungeon to the dungeon party list
	for champion in raid_party:
		var champion_dungeon_party_button = champion.create_champion_button(champion)

		champion_dungeon_party_button.connect("pressed", func(): _on_champion_button_pressed(champion, champion_dungeon_party_button))


		
		raid_party_container.add_child(champion_dungeon_party_button)
		
	update_raid_party_details_list()



func _on_add_remove_champ_button_pressed():
	#print("Add/remove button pressed")
	if selected_champion:
		#print("Removing champion:", selected_champion.champion_name)
		#print(guild_roster)	if guild_roster.find(champion) == -1:
		# Check if the champion already exists in the party
		if raid_party.find(selected_champion) == -1:
		# If the champion doesn't exist, add it to the party
			add_to_party(selected_champion)
			
		
		else :
		# If the champion exists, remove it from the party
			remove_from_party(selected_champion)
			print("Removed " + selected_champion.champion_name + " from party.")
	else :
		print("No selected champion")


#-----------------RAID SPECIFIC CODE
func _on_map_update_timer_timeout():
	update_map_with_party_position(selected_raid)
	print("Updating map with party positions for: ", selected_raid)

func _on_generate_raid_button_pressed():
	var raid_name = "Generated_raid_" + str(GlobalData.generated_raids_counter + 1)
	var raid_data = generate_raid(raid_name)
	add_raid_to_list(raid_name)
	if raid_data == null:
		print("Error: raid_data is null before calling add_raid.")
	else:
		GlobalData.add_raid(raid_data)
		GlobalData.generated_raids_counter += 1  # Increment the counter only if the raid is successfully added

func generate_raid(raid_name):
	var grid = []
	var boss_powers = []  # List to store boss powers
	#var visited_tiles = []  # Track visited tiles	
	var average_level_required = randi_range(10, 60)
	var raid_power = average_level_required * 10
	
	# Initialize grid with empty tiles
	for y in range(GRID_HEIGHT):
		var row = []
		for x in range(GRID_WIDTH):
			row.append(GlobalData.SquareType.EMPTY)
		grid.append(row)

	# Place the entrance tile
	var entrance_x = randi() % GRID_WIDTH
	grid[0][entrance_x] = GlobalData.SquareType.ENTRANCE
	var start_pos = Vector2(entrance_x, 0)
	var party_position = start_pos
	# Generate the path using backtracking
	grid = generate_path_with_backtracking(grid, start_pos)
	if grid == null:
		print("Error: Path generation failed. Raid generation aborted.")
		return null
	

	# Populate boss rooms along the path
	var visited_tiles = []  # Extract visited tiles from the generated grid
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x] == GlobalData.SquareType.WALKWAY:
				visited_tiles.append(Vector2(x, y))
	for i in range(visited_tiles.size() / 10):  # Use .size() instead of len()
		var boss_pos = visited_tiles[randi() % visited_tiles.size()]
		if grid[boss_pos.y][boss_pos.x] == GlobalData.SquareType.WALKWAY:
			grid[boss_pos.y][boss_pos.x] = GlobalData.SquareType.BOSS_ROOM
			#boss_powers.append(100)  # Assign boss power
						# Calculate boss power dynamically
			var random_multiplier = randf_range(0.7, 1.3)  # Random value between 0.7 and 1.3
			var boss_power = 10 * average_level_required * random_multiplier  # Example: 10 * average_level_required
			boss_powers.append(round(boss_power))  # Append boss power

	# Place the final boss room on the last walkway tile
	if visited_tiles.size() > 0:
		var last_tile = visited_tiles[visited_tiles.size() - 1]  # Last tile in the path
		grid[last_tile.y][last_tile.x] = GlobalData.SquareType.FINAL_BOSS_ROOM
		var random_final_boss_multiplier = randf_range(0.9, 1.5)
		var final_boss_power = 10 * average_level_required * random_final_boss_multiplier  # Example: 10 * average_level_required
		boss_powers.append(round(final_boss_power))  # Append boss power
	else:
		print("Error: No walkway tiles found for placing final boss room!")



	# Create raid data dictionary
	var raid_data = {
		"name": raid_name,
		"average_level_required": average_level_required,
		"num_dps_req": 3,
		"num_healers_req": 1,
		"num_tanks_req": 1,
		#"raid_time": 1,
		"raid_xp_reward": 100,
		"raid_copper_reward": 500,
		"raid_ilvl_reward": 5,
		"raid_power": raid_power,
		"minute_xp": 24,
		"minute_copper": 15,
		"grid": grid,
		"party_position": party_position,
		"raid_morale": 100,
		"grid_height": GRID_HEIGHT,
		"grid_width": GRID_WIDTH,
		"boss_powers": boss_powers,
		"boss_counter": 0  # Counter to track boss fights
	}

	# Debug print to visualize the grid and boss powers
	for row in grid:
		print(row)
	print("Generated boss powers: ", boss_powers)

	if raid_data == null or not raid_data.has("name"):
		print("Error: Generated raid_data is invalid: ", raid_data)
	else:
		print("Generated raid_data: ", raid_data)
	
	return raid_data

# Function to determine the next valid tile
func find_next_tile(grid, current_pos, visited_tiles):

	# Filter moves
	var valid_moves = []

	#print("Evaluating valid moves for position:", current_pos)
	#print("Visited tiles:", visited_tiles)
	#print("Grid boundaries: Width =", GRID_WIDTH, ", Height =", GRID_HEIGHT)
	var possible_moves = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]  # Up, down, left, right

	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]:  # Possible directions
		var new_pos = current_pos + dir
	
						# Check if the tile is adjacent to previously visited tiles (except current_pos)
		var is_adjacent_to_visited = false
		for adj_dir in possible_moves:
			#print("Checking if possible_moves is available for adjacency check: ", possible_moves)
			var adj_tile = new_pos + adj_dir
			#print("Checking adjacency tile viability: ", adj_tile)
			if adj_tile != current_pos and visited_tiles.has(adj_tile):
				is_adjacent_to_visited = true
				#print("Tile is adjacent to previously visited tile: ", adj_tile)
				break
		
		if is_adjacent_to_visited:
			#print("Skipping move due to adjacency to previously visited tile: ", new_pos)
			continue  # Skip this tile if it is adjacent to other visited tiles
	
	# Check boundaries and visitation
		if new_pos.x >= 0 and new_pos.x < GRID_WIDTH and new_pos.y >= 0 and new_pos.y < GRID_HEIGHT:
			if new_pos not in visited_tiles:
				valid_moves.append(new_pos)
				print("Valid move added:", new_pos)
			else:
				print("Move already visited:", new_pos)
		else:
			print("Move out of bounds:", new_pos)
			


	print("Valid moves available: ", valid_moves)
	
	if valid_moves.size() == 0:
		print("Warning: Relaxing constraints to allow fallback.")
		for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1)]:
			var fallback_pos = current_pos + dir
			if fallback_pos.x >= 0 and fallback_pos.x < GRID_WIDTH and fallback_pos.y >= 0 and fallback_pos.y < GRID_HEIGHT:
				valid_moves.append(fallback_pos)
# Ensure there's always at least one valid move
	if valid_moves.size() == 0:
		print("Error: No valid moves available. Path generation failed.")
		print("Visited tiles:", visited_tiles)
		print("Valid moves (should be empty):", valid_moves)
		return null  # Abort path generation

# Randomly select a valid move
	current_pos = valid_moves[randi() % valid_moves.size()]
	
	if valid_moves.size() > 0:
		var next_move = valid_moves[randi() % valid_moves.size()]
		print("Valid move selection successful, new current pos: ", current_pos)
		return current_pos
	else:
		print("Error: No valid moves to select from. Valid moves:", valid_moves)
		return null

func generate_path_with_backtracking(grid, start_pos):
	var visited_tiles = []  # Stack to track visited positions
	var invalid_tiles = []  # List to track invalid positions
	var current_pos = start_pos
	var backtracking = false  # Indicates if we are in backtracking mode
	
	while true:
		# Find valid moves
		var valid_moves = []
		for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]:  # Include all directions
			var new_pos = current_pos + dir
			
			# Skip out-of-bounds moves
			if new_pos.x < 0 or new_pos.x >= GRID_WIDTH or new_pos.y < 0 or new_pos.y >= GRID_HEIGHT:
				continue
			
			# Skip if adjacent to previously visited tiles (except current_pos)
			var is_adjacent_to_visited = false
			for adj_dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, -1)]:
				var adj_tile = new_pos + adj_dir
				if adj_tile != current_pos and visited_tiles.has(adj_tile):
					is_adjacent_to_visited = true
					break
			
			if is_adjacent_to_visited:
				continue
			
			# Skip already visited or invalid tiles
			if new_pos in visited_tiles or new_pos in invalid_tiles:
				continue
			
			valid_moves.append(new_pos)
		
		# If valid moves are available, proceed to the next position
		if valid_moves.size() > 0:
			var next_pos = valid_moves[randi() % valid_moves.size()]  # Randomly select a valid move
			grid[next_pos.y][next_pos.x] = GlobalData.SquareType.WALKWAY
			visited_tiles.append(current_pos)  # Push the current position onto the stack
			current_pos = next_pos
			backtracking = false  # Reset backtracking flag
		else:
			# If no valid moves are available, backtrack
			if visited_tiles.size() == 0:
				print("Error: Path generation failed. No valid moves and stack is empty.")
				break  # Exit if backtracking is not possible
			
			# Mark current position as invalid before backtracking
			invalid_tiles.append(current_pos)
			grid[current_pos.y][current_pos.x] = GlobalData.SquareType.EMPTY  # Mark as unvisited
			current_pos = visited_tiles[visited_tiles.size() - 1]  # Backtrack to the previous position
			visited_tiles = visited_tiles.slice(0, visited_tiles.size() - 1)  # Simulate removing the last element
			backtracking = true
		
		# Debugging output
		#print("Current position:", current_pos)
		#print("Visited tiles:", visited_tiles)
		#print("Invalid tiles:", invalid_tiles)
		#print("Grid state:")
		#for row in grid:
		#	print(row)
		
		# Exit when the path reaches the final row
		if not backtracking and current_pos.y == GRID_HEIGHT - 1:
			break
	
	return grid
	
# Function to check if a tile is valid
func is_valid_tile(pos, grid, visited_tiles, current_pos):
	# Check bounds
	if pos.x < 0 or pos.x >= GRID_WIDTH or pos.y < 0 or pos.y >= GRID_HEIGHT:
		return false  # Out of bounds

	# Check if the tile is already visited
	if visited_tiles.has(pos):
		return false

	# Prevent revisiting the entrance
	if pos.y == 0 and grid[pos.y][pos.x] == GlobalData.SquareType.ENTRANCE:
		return false

	# Prevent backtracking upwards near walls
	if pos.y == current_pos.y - 1:  # Moving upward
		if pos.x in [0, 1, GRID_WIDTH - 2, GRID_WIDTH - 1]:  # Near walls
			return false

	# Ensure adjacent connection
	var adjacent_tiles = [
		Vector2(pos.x - 1, pos.y),  # Left
		Vector2(pos.x + 1, pos.y),  # Right
		Vector2(pos.x, pos.y - 1),  # Up
		Vector2(pos.x, pos.y + 1)   # Down
	]

	var has_adjacent_walkway = false
	for adj in adjacent_tiles:
		if adj.x >= 0 and adj.x < GRID_WIDTH and adj.y >= 0 and adj.y < GRID_HEIGHT:
			if grid[adj.y][adj.x] == GlobalData.SquareType.WALKWAY:
				has_adjacent_walkway = true
				break

	return has_adjacent_walkway

func generate_walkway(grid, start_pos):
	var length = randi() % 7 + 3  # Length between 3 and 9
	var current_pos = start_pos
	for i in range(length):
		var direction = randi() % 3
		match direction:
			0:
				if current_pos.x > 0:
					current_pos.x -= 1  # West
			1:
				if current_pos.x < GRID_WIDTH - 1:
					current_pos.x += 1  # East
			2:
				if current_pos.y < GRID_HEIGHT - 1:
					current_pos.y += 1  # North
		if grid[current_pos.y][current_pos.x] == GlobalData.SquareType.EMPTY:
			grid[current_pos.y][current_pos.x] = GlobalData.SquareType.WALKWAY
	return current_pos

func generate_boss_room(grid, start_pos, boss_powers):
	var direction = randi() % 3
	var boss_pos = start_pos
	match direction:
		0:
			if boss_pos.x > 0:
				boss_pos.x -= 1  # West
		1:
			if boss_pos.x < GRID_WIDTH - 1:
				boss_pos.x += 1  # East
		2:
			if boss_pos.y < GRID_HEIGHT - 1:
				boss_pos.y += 1  # North
	grid[boss_pos.y][boss_pos.x] = GlobalData.SquareType.BOSS_ROOM
	boss_powers.append(100)  # Assign boss power
	return boss_pos

func add_raid_to_list(raid_name):
	var raid_button = Button.new()
	raid_button.text = raid_name
	raid_button.connect("pressed", Callable(self, "_on_raid_button_pressed").bind(raid_name))
	generated_raid_container.add_child(raid_button)
		# Store the button in the array
	raid_buttons.append(raid_button)

func update_map_with_party_position(selected_raid):
	if not DungeonManager.active_raids.has(selected_raid):
		print("No active raid found for name: ", selected_raid)
		return
	
	var raid = DungeonManager.active_raids[selected_raid]
	var grid = raid["data"]["grid"]
	var current_pos = raid["position"]
#	print("Current raid party: ", DungeonManager.active_raids[selected_raid]["party_members"])
	var tilemap_node = $CanvasLayer/Control/RaidMapTileMap
	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	is_party_tile = !is_party_tile  # Toggle the flag	
	# Toggle the party position tile
	tilemap_node.toggle_party_position_tile(map_overlay, current_pos, is_party_tile)

	#print("Blink Timer: Current position is ", selected_raid, current_pos, " Toggle state: ", is_party_tile)
	
func _on_map_opened(raid_name: String):
	# Store the current raid name
	selected_raid = raid_name
	
	# Ensure the map is updated immediately
	update_map_with_party_position(selected_raid)
	
	# Start the map update timer
	map_update_timer.start()
	print("Started the Map Update Timer: ", map_update_timer)

func _on_map_closed():
	# Stop the map update timer
	map_update_timer.stop()
	print("Stopped the Map Update Timer: ", map_update_timer)
	# Optionally, clear the current_raid_name
	#current_raid_name = ""


func _on_active_raid_button_pressed(raid_name):
	selected_raid = raid_name
	print("Selected an active raid: " + selected_raid)
	
	#is_party_tile = false

	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	var current_pos = Vector2(0, 0)
	
	var tilemap_node = $CanvasLayer/Control/RaidMapTileMap
	if tilemap_node == null:
		print("Error: RaidMapTileMap is not found in the scene tree.")
		return
		# Toggle the party position tile
	#tilemap_node.toggle_party_position_tile(map_overlay, current_pos, is_party_tile)
	tilemap_node.clear_party_position_tile(map_overlay)
		
	var raid_data = GlobalData.get_raid_data(raid_name)
	if raid_data.size() == 0:  # Check if the dictionary is empty
		print("Raid data not found for:", raid_name)
		return
	# Pass the raid data to the TileMap for visualization
	print("Passing grid from raid data to TileMap: ", raid_data["grid"])
	$CanvasLayer/Control/RaidMapTileMap.update_raid_map(raid_data["grid"])
	
	map_update_timer.start()
	#update_map_with_party_position(selected_raid)
	
	
	# Clear previous labels
	for child in raid_info_container.get_children():
		raid_info_container.remove_child(child)
		child.queue_free()
	
		# Display raid_data properties as text labels
	for key in raid_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(raid_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		raid_info_container.add_child(label)

func _on_raid_button_pressed(raid_name):
	selected_raid = raid_name
	print("Selected raid is: " + selected_raid)
	
	map_update_timer.stop()
	is_party_tile = false

	
	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	#var current_pos = Vector2(0, 0)
	
	var tilemap_node = $CanvasLayer/Control/RaidMapTileMap
	if tilemap_node == null:
		print("Error: RaidMapTileMap is not found in the scene tree.")
		return
		# Toggle the party position tile
	tilemap_node.clear_party_position_tile(map_overlay)
	
	var raid_data = GlobalData.get_raid_data(raid_name)
	if raid_data.size() == 0:  # Check if the dictionary is empty
		print("Raid data not found for:", raid_name)
		return
	# Pass the raid data to the TileMap for visualization
	#print("Passing grid from raid data to raid map: ", raid_data["grid"])
	$CanvasLayer/Control/RaidMapTileMap.update_raid_map(raid_data["grid"])
	
	#map_update_timer.start()
	#update_map_with_party_position(selected_raid)
	
	
	# Clear previous labels
	for child in raid_info_container.get_children():
		raid_info_container.remove_child(child)
		child.queue_free()
	
		# Display raid_data properties as text labels
	for key in raid_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(raid_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		raid_info_container.add_child(label)
	
	
func add_raid_options(options):
	# Clear existing items in the dropdown menu
	raid_dropdown.clear()

	# Add each activity option as a new item in the dropdown menu
	for option in options:
		raid_dropdown.add_item(option)
		


func _on_start_raid_button_pressed():
	if selected_raid == null:
		print("Please select a raid")
		return

	var raid_name = selected_raid	
	
	var raid_data = GlobalData.raids[raid_name]

		# Check raid party requirements
	var num_tanks = 0
	var num_healers = 0
	var num_dps = 0
	var total_level = 0

	for champion in raid_party:
		total_level += champion.champion_xp_level
		if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
			num_tanks += 1
		elif champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
			num_healers += 1
		elif champion.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Necromancer", "Stalker"]:
			num_dps += 1

	var average_level = total_level / float(raid_party.size())
	print("Average Level: " + str(average_level))  # Debug print to check average level

	# Check if the party meets the raid requirements
	if average_level < raid_data["average_level_required"]:
		print("The average level of the party must be " + str(raid_data["average_level_required"]) + " or more.")
		return

	if num_tanks < raid_data["num_tanks_req"]:
		print("The party needs at least " + str(raid_data["num_tanks_req"]) + " tank(s).")
		return

	if num_healers < raid_data["num_healers_req"]:
		print("The party needs at least " + str(raid_data["num_healers_req"]) + " healer(s).")
		return

	if num_dps < raid_data["num_dps_req"]:
		print("The party needs at least " + str(raid_data["num_dps_req"]) + " DPS.")
		return

	# Assuming the requirements are met
	var raid_party_name = raid_name + "_party"
	var grid = raid_data["grid"]  # Retrieve the grid from the raid data	
	GlobalData.add_raid_party(raid_party_name, raid_party, grid) 

	for champion in raid_party:
		champion.champion_status = str("In raid: ", raid_name)
		print("Champion: ", champion.champion_name, " status changed to: ", champion.champion_status)
	
	if raid_name in GlobalData.raids:
		print("Starting raid: ", raid_name)
		print("Sending to start global data startraid, which sends to DungeonManager:", raid_name)
		GlobalData.start_raid(raid_name)

		print("GlobalData start_raid and DungeonManager start_raid comepleted. Content of raid_party:", raid_party)
		print("Current raid party in Dung Man: ", DungeonManager.active_raids[selected_raid]["party_members"])
		# Generate the button for the ActiveRaidPartiesContainer
		var active_raid_button = Button.new()
		active_raid_button.text = raid_party_name
		active_raid_button.name = raid_party_name
		active_raid_button.connect("pressed", Callable(self, "_on_raid_button_pressed").bind(raid_party_name))
		active_raid_party_container.add_child(active_raid_button)
		active_raid_button.connect("pressed", func(): _on_active_raid_button_pressed(raid_name))
		
		
		
		# Update the button reference in the existing raid_timers entry
		if GlobalData.raid_timers.has(raid_party_name):
			GlobalData.raid_timers[raid_party_name]["button"] = active_raid_button
			print("Button created and stored in raid_timers for: ", raid_party_name)
		else:
			print("Error: Attempting to add a button for a raid timer that doesn't exist:", raid_party_name)

		# Debug print to check the state of raid_timers
		print("function on_start_raid_button_pressed: Updated raid_timers:", GlobalData.raid_timers)
		
# Use the helper function
		if find_raid_by_name(raid_name):
			GlobalData.remove_raid_from_generated(raid_name)
			print("Removed Raid:", raid_name)
		else:
			print("Raid not found in Global Data:", raid_name)
		
		#if generated_raid_found:
		#	GlobalData.remove_raid_from_generated(raid_name)
		#	print("Removed Raid:", raid_name)
		
		
		for button in raid_buttons:
			if button.text == raid_name:
				# Remove button from the container
				generated_raid_container.remove_child(button)
				# Remove from the array
				raid_buttons.erase(button)
				# Free the button
				button.queue_free()
				#return  # Exit the loop once the button is removed
			print("Button not found for raid:", raid_name)
		#if generated_raid_container.has_node("RaidButton"):
		#	var generated_raid_button = generated_raid_container.get_node("RaidButton")
		#	generated_raid_container.remove_child(generated_raid_button)
		#	generated_raid_button.queue_free()  # Optional	
		
	else:
		print("Raid not found in global data raids:", raid_name)	
		

	if GlobalData.raid_timers.has(raid_party_name):
		print("On start raid button executed correctly! Raid timers: ", GlobalData.raid_timers)
		_on_map_opened(selected_raid)
		print("Current raid party in Dung Man: ", DungeonManager.active_raids[selected_raid]["party_members"])	
		
	else:
		print("On start raid button messed up the raid timers: ", GlobalData.raid_timers)	
	
# Check if raid_party has something in it
	if raid_party.size() > 0:  # Or alternatively: if not raid_party.empty():
	# Clear the raid_party array
#		print("Raid party has content: ", raid_party, " ... attempting to clear raid_party array")
#		raid_party.clear()
	
	# Update the raid_party list
#		update_raid_party_list()
	
	# Clear all children of the raid_party_container and raid_party_details_container
		clear_container_children(raid_party_container)
		clear_container_children(raid_party_details_container)
		print("Raid party should be cleared now: ", raid_party)
		print("Current raid party in Dung Man: ", DungeonManager.active_raids[selected_raid]["party_members"])		

func find_raid_by_name(raid_name):
	for raid_data in GlobalData.generated_raids:
		if raid_data.name == raid_name:
			return true
	return false


func _on_party_button_pressed(raid_name):
	var tilemap_node = $CanvasLayer/Control/RaidMapTileMap
	if tilemap_node == null:
		print("Error: RaidMapTileMap is not found in the scene tree.")
		return
	
	var raid_data = GlobalData.get_raid_data(raid_name)
	if raid_data.size() == 0:  # Check if the dictionary is empty
		print("Raid data not found for:", raid_name)
		return
	
	# Pass the raid data to the TileMap for visualization
	$CanvasLayer/Control/RaidMapTileMap.update_raid_map(raid_data["grid"])
	
	# Clear previous labels
	for child in raid_info_container.get_children():
		raid_info_container.remove_child(child)
		child.queue_free()
	
	# Display raid_data properties as text labels
	for key in raid_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(raid_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		raid_info_container.add_child(label)



func update_raid_button_text(raid_party_name):
	# Check if the raid timers entry exists
	if not GlobalData.raid_timers.has(raid_party_name):
		print("Raid party ID", raid_party_name, "is no longer active.")
		clear_container_children(active_raid_party_container)
		return

	# Retrieve the countdown time
	var countdown_time = GlobalData.get_raid_time(raid_party_name)
	if countdown_time == null:
		print("Error: Could not retrieve countdown time for raid party:", raid_party_name)
		return
	
	var raid_name = raid_party_name.left(raid_party_name.length() - 6)  # Remove last 6 characters


				
	# Check if the button exists and update its text
	if GlobalData.raid_timers[raid_party_name].has("button"):
		var active_raid_button = GlobalData.raid_timers[raid_party_name]["button"]
		if active_raid_button != null:
			# Update button text			
			var minutes = int(countdown_time / 60)
			var seconds = int(countdown_time % 60)
			var formatted_time = str("%02d:%02d" % [minutes, seconds])
			active_raid_button.text = raid_party_name + " - " + formatted_time
			print("Updated button for raid party: ", raid_party_name, " with time: ", formatted_time)
		else:
			# Create a new button if it doesn't exist
			active_raid_button = Button.new()
			active_raid_button.text = raid_party_name  # Placeholder text; updated below
			active_raid_button.name = raid_party_name
			active_raid_button.connect("pressed", Callable(self, "_on_active_raid_button_pressed").bind(raid_party_name))
			active_raid_party_container.add_child(active_raid_button)
			active_raid_button.connect("pressed", func(): _on_active_raid_button_pressed(raid_name))
			var minutes = int(countdown_time / 60)
			var seconds = int(countdown_time % 60)
			var formatted_time = str("%02d:%02d" % [minutes, seconds])
			active_raid_button.text = raid_party_name + " - " + formatted_time
			print("Recreated and updated button for raid party:", raid_party_name, "with time: ", formatted_time)
			# Store the new button reference in raid_timers
			GlobalData.raid_timers[raid_party_name]["button"] = active_raid_button
			#print("Recreated raid button for:", raid_party_name)
	else:
		print("Error: Button reference not found for raid party:", raid_party_name)
		clear_container_children(active_raid_party_container)
	# Optional: Debugging output for current state
	#print("function update_raid_button_text - Current raid_timers:", GlobalData.raid_timers)



func start_raid(raid_name, average_level_required, num_dps_req, num_healers_req, num_tanks_req, raid_time, raid_xp_reward, raid_copper_reward, raid_ilvl_reward, raid_power, minute_xp, minute_copper):
	var num_tanks = 0
	var num_healers = 0
	var num_dps = 0
	
	# Temporary list to hold champions for the dungeon party
	var party_members = []

	# Debug: Print the current state of dungeon_party
	print("Starting Dungeon:", raid_name)
	print("Content of dungeon_party:", raid_party)

	# Calculate the total and average level of champions in the dungeon party
	var total_level = 0
	for champion in raid_party:
		total_level += champion.champion_xp_level
	
	var average_level = total_level / float(raid_party.size())
	
	print("Average Level: " + str(average_level))  # Debug print to check average level

	# Check if the average level meets the requirement
	if average_level < average_level_required:
		print("The average level of the party must be " + str(average_level_required) + " or more.")
		return  # Exit the function if the requirement is not met

	# Iterate through the dungeon party
	for champion in raid_party:
		# Check if the champion is a tank
		if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
			if num_tanks < num_tanks_req:
				party_members.append(champion)
				num_tanks += 1
				print("Found Tank:", champion.champion_name)

		# Check if the champion is a healer
		elif champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
			if num_healers < num_healers_req:
				party_members.append(champion)
				num_healers += 1
				print("Found Healer:", champion.champion_name)

		# Check if the champion is a DPS (either ranged or melee)
		elif champion.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Necromancer", "Stalker"]:
			if num_dps < num_dps_req:
				party_members.append(champion)
				num_dps += 1
				print("Found Damage Dealers:", champion.champion_name)
				
		# Check if the party composition is complete
		if num_tanks >= num_tanks_req and num_healers >= num_healers_req and num_dps >= num_dps_req:
			var ready_check_complete = true
			print("Party is complete")

	# Check if the party composition meets the requirements
	if num_tanks == num_tanks_req and num_healers == num_healers_req and num_dps == num_dps_req:
		# Set the status of party members to "In Dungeon"
		for member in party_members:
			member.champion_status = "In " + raid_name
		
		# Create a new party button with a countdown timer
		var party_id = raid_name + "_Party_" + str(GlobalData.active_raid_parties.size() + 1)
		var party_button = Button.new()
		active_raid_party_container.add_child(party_button)
		
		var initial_time = raid_time * 60  # Convert minutes to seconds

		# Store the button in the dictionary for reference
		party_timers[party_id] = {"button": party_button}
		print("Added party to timers:", party_id, "with initial_time:", initial_time)  # Debug print to verify addition
		


		# Add the party to the GlobalData singleton with initial time and dungeon time
		GlobalData.add_party(party_id, party_members, initial_time, raid_time, raid_xp_reward, raid_copper_reward, raid_ilvl_reward, raid_power, minute_xp, minute_copper)
		
		# Remove the champions from the dungeon party
		for champion in party_members:
			if raid_party.has(champion):
				raid_party.erase(champion)
		update_raid_party_list()
		
		clear_container_children(raid_party_container)
		
		# Debug: Print the current state of the dictionaries
		print("Dungeon started. Active Dungeon Parties:", GlobalData.active_dungeon_parties)
		print("Dungeon started. Party Timers:", GlobalData.party_timers)
		
	else:
		print("Party composition does not meet requirements.")



func _on_timer_timeout():
		if GlobalData.raid_timers != null:
			for raid_party_name in GlobalData.raid_timers.keys():
				update_raid_button_text(raid_party_name)
				print("Calling update_raid_button_text on raid_party_name: ", raid_party_name)
			return
		else:
			clear_container_children(active_raid_party_container)


func _exit_tree():
	# Deregister this scene with GlobalData
	if GlobalData.raid_play_scene_ref == self:
		GlobalData.raid_play_scene_ref = null
		print("Deregistered raid_play_scene from GlobalData.")


func _on_raid_options_item_selected(index):
	selected_raid = raid_dropdown.get_item_text(index)
	print("Selected raid is: " + selected_raid)
	is_party_tile = false
	
	var tilemap_node = $CanvasLayer/Control/RaidMapTileMap

	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	# Toggle the party position tile
	tilemap_node.toggle_party_position_tile(map_overlay, (null), is_party_tile)
	
	var raid_data = GlobalData.get_raid_data(selected_raid)
	if raid_data.size() == 0:  # Check if the dictionary is empty
		print("Raid data not found for:", selected_raid)
		return
	# Pass the raid data to the TileMap for visualization
	$CanvasLayer/Control/RaidMapTileMap.update_raid_map(raid_data["grid"])
	
		# Clear previous labels
	for child in raid_info_container.get_children():
		raid_info_container.remove_child(child)
		child.queue_free()
	
		# Display raid_data properties as text labels
	for key in raid_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(raid_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		raid_info_container.add_child(label)
