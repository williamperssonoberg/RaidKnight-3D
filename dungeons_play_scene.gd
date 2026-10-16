extends Node2D

@onready var add_champion_to_crawl_party_button = get_node("%AddChampionToCrawlPartyButton")
@onready var crawler_party_grid = get_node("%CrawlerPartyGrid")
@onready var selected_panel = $SelectedChampionPanel
@onready var start_crawl_button = get_node("%StartCrawlButton")
@onready var dungeonDifficutlyButton = get_node("%DungeonDifficultyButton")
@onready var dungeonLevelButton = get_node("%DungeonLevelButton")
@onready var championPanel = %ChampionPanel

# Dictionary to store champion assignments
var formation_data = {}
var selected_slot = null

var preset_dungeons_raids = preload("res://preset_dungeons_raids.gd").new()
var dungeon_data = preset_dungeons_raids.dungeon_data
var guild_roster = [] # List to store champions in the guild roster
var champion_ui_container
var champion_details_container
var active_dungeon_party_container
var dungeon_party_container
var roster_list # Reference to UI element displaying the guild roster
var selected_champion # Declare a variable to store the currently selected champion
var selected_dungeon = "Idle"  # Variable to store the currently selected dungeon
#var global_data_node
var MAX_PARTY_SIZE = 5
var dungeon_party = [] #list to store dungeon party
var dungeon_dropdown
var dungeon_party_details_container
var active_dungeon_parties = []
var dps_container_1 = {"node": null, "role": Role.DPS}
var dps_container_2 = {"node": null, "role": Role.DPS}
var dps_container_3 = {"node": null, "role": Role.DPS}
var tank_container = {"node": null, "role": Role.TANK}
var healer_container = {"node": null, "role": Role.HEALER}
var dungeon_power = 5  # Example dungeon power value
var party_timers = {}  # Dictionary to store references to buttons
# Enum to represent roles
enum Role { TANK, HEALER, DPS }
var champion_data_node
var chat_panel_scene = preload("res://ChatPanel.tscn")
# Define specific rewards for each dungeon
var map_update_timer = Timer.new()
var dungeon_info_container
var is_party_tile = false
var dungeon_buttons = [] # Array to store the raid buttons for easy reference
#double click tracker
var last_click_time = 0.0
const DOUBLE_CLICK_INTERVAL = 0.3  # Max time (in seconds) between clicks to register as double-click
var dungeon_difficulty = "normal"
var dungeon_level = 1
	
func _ready():
	print("Dungeon scene ready!")
	# Connect each slot button to selection function
	for slot in crawler_party_grid.get_children():
		slot.connect("pressed", Callable(self, "_on_slot_selected").bind(slot))
		

	# Connect the Add Champion button
	add_champion_to_crawl_party_button.connect("pressed", Callable(self, "_on_add_champion_to_crawl_party_pressed"))

	map_update_timer.name = "Map Update Timer"  # Give the timer a name to easily reference it later
	map_update_timer.set_wait_time(0.5)
	map_update_timer.set_one_shot(false)
	map_update_timer.connect("timeout", Callable(self, "_on_map_update_timer_timeout"))
	add_child(map_update_timer)
	map_update_timer.start()
	#global_data_node = get_node("/root/GlobalData")
	dungeon_info_container = get_node("CanvasLayer/Control/DungeonMapTileMap/DungeonInfoContainer")

	dungeon_party_details_container = get_node("CanvasLayer/Control/DungeonPartyDetailsContainer")
	champion_ui_container = get_node("CanvasLayer/Control/ChampionUIContainer")
	champion_details_container = get_node("CanvasLayer/Control/ChampionDetailsContainer")
	roster_list = get_node("CanvasLayer/Control/GuildRosterContainer")
	dungeon_party_container = get_node("CanvasLayer/Control/DungeonPartyContainer")
	active_dungeon_party_container = get_node("CanvasLayer/Control/ActiveDungeonPartiesContainer")
	print("Party Timer type:", typeof(party_timers))
	
	# Clear the container first
	clear_container_children(active_dungeon_party_container)

	# Restore the party members and timers from GlobalData
	for party_id in GlobalData.dungeon_parties.keys():
		update_party_button_text(party_id)

	  # Load the PackedScene
	var chat_panel = chat_panel_scene.instantiate()  # Create an instance of the scene
	add_child(chat_panel)  # Add the instance to the scene tree

	# Set up a timer to periodically update the buttons
	var timer = Timer.new()
	timer.name = "Timer"  # Give the timer a name to easily reference it later
	timer.set_wait_time(1.0)
	timer.set_one_shot(false)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()


	_populate_dungeon_level_dropdown()
	# Set default level to "1"
	dungeonLevelButton.select(0)
	dungeonLevelButton.connect("item_selected", _on_dungeon_level_selected)

	# Populate the OptionButton with difficulty options
	for label in difficulty_mapping.keys():
		dungeonDifficutlyButton.add_item(label)  

	# Set default selection to "Normal"
	dungeonDifficutlyButton.select(0)
	dungeon_difficulty = difficulty_mapping["Normal"]
		# Connect selection signal
	dungeonDifficutlyButton.connect("item_selected", _on_difficulty_selected)
	#add_remove_champ_button = get_node("CanvasLayer/Control/AddRemoveChampButton")

	
		# Assign roles to containers
	dps_container_1["node"] = get_node("CanvasLayer/Control/DPScontainer1")
	#dps_container_1 = Role.DPS
	dps_container_2["node"] = get_node("CanvasLayer/Control/DPScontainer2")
	#dps_container_2 = Role.DPS
	dps_container_3["node"] = get_node("CanvasLayer/Control/DPScontainer3")
	#dps_container_3 = Role.DPS
	tank_container["node"] = get_node("CanvasLayer/Control/Tankcontainer")
	#tank_container = Role.TANK
	healer_container["node"] = get_node("CanvasLayer/Control/Healercontainer")
	#healer_container = Role.HEALER
	
	show_global_roster_list()

	dungeon_dropdown = get_node("CanvasLayer/Control/DungeonOptions")
	# List of activity options
	var dungeon_options = ["Idle", "Dungeon 1", "Dungeon 2", "Dungeon 3", "Dungeon 4", "Dungeon 5", "Dungeon 6"]
	# Add activity options to the dropdown menu
	add_dungeon_options(dungeon_options)
	#print("Adding dungeon data to GlobalData: ", dungeon_data)
	GlobalData.add_dungeon(dungeon_data)
	
	
	
	set_process_input(true)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#--------------------------------------------------------------------------------------Champion list and details

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
	
	print(guild_roster)	

	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = champion.create_champion_button(champion)
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
	_on_character_drag_start(button)
	
func _on_champion_button_double_clicked(champion, button):
	# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	update_champion_details(champion)
	selected_champion = champion
	_on_character_drag_start(button)
	
	if selected_champion:

		if dungeon_party.find(selected_champion) == -1:
		# If the champion doesnt exists, remove it from the party
			add_to_party(selected_champion)
			
		
		else :
		# If the champion exists, remove it from the party
			remove_from_party(selected_champion)
			print("Removed " + selected_champion.champion_name + " from party.")
	else :
		print("No selected champion")
	

# Function to update the roster list UI element
func update_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	
	GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = Button.new()
		champion_roster_button.text = champion.champion_name

		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion, champion_roster_button))
		
				# Set background color based on champion's class
		match champion.champion_class:
			"Rogue":
				champion_roster_button.modulate = Color("#FFF468")
			"Priest":
				champion_roster_button.modulate = Color("#FFFFFF")
			"Fighter":
				champion_roster_button.modulate = Color("#C69B6D")
			"Crusader":
				champion_roster_button.modulate = Color("#F48CBA")
			"Shaman":
				champion_roster_button.modulate = Color("#0070DD")
			"Wizard":
				champion_roster_button.modulate = Color("#8788EE")
			_:
			# Default color if champion class is not recognized
				champion_roster_button.modulate = Color(1, 1, 1) # White
		
		roster_list.add_child(champion_roster_button)


# -----------------------------------------------------functions to add and remove champions as party members




func remove_from_party(champion):

	# Check if the champion exists in the party
	if dungeon_party.find(champion) != -1:
	#if index 
		# If the champion exists, remove it from the party
		dungeon_party.erase(champion)
		
	update_dungeon_party_list()
	#else:
	#	print("Champion is not in the party!")
		

func add_to_party(champion):

	 # Check if the champion already exists in the party
	if dungeon_party.size() < MAX_PARTY_SIZE:
		
		if dungeon_party.find(champion) == -1:
		# If the champion doesn't exist, add it to the party
			dungeon_party.append(champion)
			print("Added " + champion.champion_name + " to party.")
			update_dungeon_party_list()
		else:
			pass
	else:
		print("Maximum party size reached. Cannot add more champions.")	
	
	#else:
	#	print("Champion is arlready in the party!")

func update_dungeon_party_details_list():
	 # Clear the list content
	clear_container_children(dungeon_party_details_container)
	var num_tanks = 0
	var num_healers = 0
	var num_dps = 0	
	var combined_power = 0
			
	for champion in dungeon_party:
		
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
						dungeon_party_details_container.add_child(skillful_healer_label)
				"Skillful_Tank":
					if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
						adjusted_power *= 1.05
						var skillful_tank_label = Label.new()
						skillful_tank_label.text = champion.champion_name + " is skillful Tank! 5% bonus power"
						dungeon_party_details_container.add_child(skillful_tank_label)
				"Skillful_Melee_DPS":
					if champion.champion_specialization in ["Berserker", "Stalker", "Wind"]:
						adjusted_power *= 1.05
						var skillful_melee_label = Label.new()
						skillful_melee_label.text = champion.champion_name + " is skillful Melee DPS! 5% bonus power"
						dungeon_party_details_container.add_child(skillful_melee_label)
				"Skillful_Ranged_DPS":
					if champion.champion_specialization in ["Voodoo", "Fire", "Scholar"]:
						adjusted_power *= 1.05
						var skillful_ranged_label = Label.new()
						skillful_ranged_label.text = champion.champion_name + " is skillful Ranged DPS! 5% bonus power"
						dungeon_party_details_container.add_child(skillful_ranged_label)
				"None":
					pass
			
		# Check if the champion is a tank
		if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
			num_tanks += 1

		# Check if the champion is a healer
		elif champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
			num_healers += 1

		# Check if the champion is a DPS (either ranged or melee)
		elif champion.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Scholar", "Stalker"]:
			num_dps += 1
				
		# Ensure adjusted_power is valid
		if adjusted_power == null:
			adjusted_power = base_power

		# Add the adjusted power to the combined power
		combined_power += adjusted_power
		
		print(champion.champion_name, "base power:", base_power, "adjusted power:", adjusted_power)

	
	var dungeon_party_combined_power_label = Label.new()
	dungeon_party_combined_power_label.text = "Total party power is " + str(combined_power)
	dungeon_party_details_container.add_child(dungeon_party_combined_power_label)
	
	var dungeon_party_tanks_label = Label.new()
	dungeon_party_tanks_label.text = "Tanks: " + str(num_tanks)
	dungeon_party_details_container.add_child(dungeon_party_tanks_label)
	
	var dungeon_party_healers_label = Label.new()
	dungeon_party_healers_label.text = "Healers: " + str(num_healers)
	dungeon_party_details_container.add_child(dungeon_party_healers_label)
	
	var dungeon_party_dps_label = Label.new()
	dungeon_party_dps_label.text = "DPS: " + str(num_dps)
	dungeon_party_details_container.add_child(dungeon_party_dps_label)		
		
	var dungeon_dropdown = get_node("CanvasLayer/Control/DungeonOptions")
	var selected_dungeon_index = dungeon_dropdown.selected
	
	

	if selected_dungeon == "Idle":
		return  # No dungeon selected
		
	
		
	if dungeon_data.has(selected_dungeon):
		var data = dungeon_data[selected_dungeon]
		var selected_dungeon = dungeon_dropdown.get_item_text(selected_dungeon_index)	
		var dungeon_power = data["dungeon_power"]
		var success_chance = float(combined_power) / dungeon_power
		var dungeon_party_success_label = Label.new()
		dungeon_party_success_label.text = "Success chance: " + str(success_chance)
		dungeon_party_details_container.add_child(dungeon_party_success_label)

func update_dungeon_party_list():
	 # Clear the list content
	clear_container_children(dungeon_party_container)

	
	# Add champions in the dungeon to the dungeon party list
	for champion in dungeon_party:
		var champion_dungeon_party_button = champion.create_champion_button(champion)

		champion_dungeon_party_button.connect("pressed", func(): _on_champion_button_pressed(champion, champion_dungeon_party_button))
		

		
		dungeon_party_container.add_child(champion_dungeon_party_button)
		
	update_dungeon_party_details_list()



func _on_add_remove_champ_button_pressed():
	#print("Add/remove button pressed")
	if selected_champion:
		#print("Removing champion:", selected_champion.champion_name)
		#print(guild_roster)	if guild_roster.find(champion) == -1:
		# Check if the champion already exists in the party
		if dungeon_party.find(selected_champion) == -1:
		# If the champion doesn't exist, add it to the party
			add_to_party(selected_champion)
			
		
		else :
		# If the champion exists, remove it from the party
			remove_from_party(selected_champion)
			print("Removed " + selected_champion.champion_name + " from party.")
	else :
		print("No selected champion")



# -----------------------------------------------------functions to select and start dungeon

func add_dungeon_options(options):
	# Clear existing items in the dropdown menu
	dungeon_dropdown.clear()

	# Add each activity option as a new item in the dropdown menu
	for option in options:
		dungeon_dropdown.add_item(option)

func _on_active_dungeon_button_pressed(dungeon_name):
	selected_dungeon = dungeon_name
	print("Selected an active raid: " + selected_dungeon)
	
	#is_party_tile = false

	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	var current_pos = Vector2(0, 0)
	
	var tilemap_node = $CanvasLayer/Control/DungeonMapTileMap
	if tilemap_node == null:
		print("Error: DungeonMapTileMap is not found in the scene tree.")
		return
		# Toggle the party position tile
	#tilemap_node.toggle_party_position_tile(map_overlay, current_pos, is_party_tile)
	tilemap_node.clear_party_position_tile(map_overlay)
		
	var dungeon_data = GlobalData.get_dungeon_data(dungeon_name)
	if dungeon_data.size() == 0:  # Check if the dictionary is empty
		print("Dungeon data not found for:", dungeon_name)
		return
	# Pass the raid data to the TileMap for visualization
	$CanvasLayer/Control/DungeonMapTileMap.update_raid_map(dungeon_data["grid"])
	
	map_update_timer.start()
	update_map_with_party_position(selected_dungeon)
	
	
	# Clear previous labels
	for child in dungeon_info_container.get_children():
		dungeon_info_container.remove_child(child)
		child.queue_free()
	
		# Display raid_data properties as text labels
	for key in dungeon_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(dungeon_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		dungeon_info_container.add_child(label)

func update_map_with_party_position(selected_dungeon):
	if not DungeonManager.active_dungeons.has(selected_dungeon):
		#print("No active raid found for name: ", selected_dungeon)
		return
	
	var dungeon = DungeonManager.active_dungeons[selected_dungeon]
	var grid = dungeon["data"]["grid"]
	var current_pos = dungeon["position"]
	var tilemap_node = $CanvasLayer/Control/DungeonMapTileMap
	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	is_party_tile = !is_party_tile  # Toggle the flag	
	# Toggle the party position tile
	tilemap_node.toggle_party_position_tile(map_overlay, current_pos, is_party_tile)

func _on_dungeon_options_item_selected(index):
	#print("menu selected")
	# Get the selected activity option
	selected_dungeon = get_node("CanvasLayer/Control/DungeonOptions").get_item_text(index)
	print("Selected Dungeon:", selected_dungeon)  # Debug statement
	# Perform actions based on the selected activity
	
	# Update dungeon_info_label with relevant information
	var dungeon_info_label = get_node("CanvasLayer/Control/DungeonInfoLabel")
	match selected_dungeon:
		"Idle":
			dungeon_info_label.text = "No dungeon selected. Please choose a dungeon to start."
		"Dungeon 1":
			dungeon_info_label.text = "Dungeon 1: A beginner dungeon suitable for about level 10. Dungeon power lvl 50."
		"Dungeon 2":
			dungeon_info_label.text = "Dungeon 2: An intermediate dungeon suitable for about level 20. Dungeon power lvl 100."
		"Dungeon 3":
			dungeon_info_label.text = "Dungeon 3: An advanced dungeon for experienced champions. Dungeon power lvl 175."
		"Dungeon 4":
			dungeon_info_label.text = "Dungeon 4: An advanced dungeon for experienced champions. Dungeon power lvl 250."
		"Dungeon 5":
			dungeon_info_label.text = "Dungeon 5: An advanced dungeon for experienced champions. Dungeon power lvl 350."
		"Dungeon 6":
			dungeon_info_label.text = "Dungeon 6: An advanced dungeon for experienced champions. Dungeon power lvl 475."
		_:
			dungeon_info_label.text = "Select your next adventure!"
			# Handle Activity 3
		# Add more cases as needed
	update_dungeon_party_details_list()

	is_party_tile = false
	
	var tilemap_node = $CanvasLayer/Control/DungeonMapTileMap

	var map_overlay = $CanvasLayer/Control/map_overlay  # Reference the overlay TileMap
	
	# Toggle the party position tile
	tilemap_node.toggle_party_position_tile(map_overlay, (null), is_party_tile)
	
	var dungeon_data = GlobalData.get_dungeon_data(selected_dungeon)
	if dungeon_data.size() == 0:  # Check if the dictionary is empty
		print("Dungeon data not found for: ", selected_dungeon)
		return
	# Pass the raid data to the TileMap for visualization
	$CanvasLayer/Control/DungeonMapTileMap.update_raid_map(dungeon_data["grid"])
	
		# Clear previous labels
	for child in dungeon_info_container.get_children():
		dungeon_info_container.remove_child(child)
		child.queue_free()
	
		# Display raid_data properties as text labels
	for key in dungeon_data:
		if key == "grid":  # Skip the grid property since it is used for the TileMap
			continue
		
		# Create a new label for each key-value pair
		var label = Label.new()
		label.text = key.capitalize() + ": " + str(dungeon_data[key])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Add the label to the raid_info_container
		dungeon_info_container.add_child(label)



func stop_activity(champion):
	# Check if the champion is currently engaged in an activity
	if champion.champion_status != "Idle":
		# Stop any ongoing activity-related actions, such as timers
		# Reset the champion's status to "Idle"
		champion.champion_status = "Idle"
	else:
		print(champion.champion_name + " is already idle!")
		



# Function to create a dungeon party with the specified composition

func start_dungeon(dungeon_name, average_level_required, num_dps_req, num_healers_req, num_tanks_req, dungeon_time, dungeon_xp_reward, dungeon_copper_reward, dungeon_ilvl_reward, dungeon_power, minute_xp, minute_copper):
	var num_tanks = 0
	var num_healers = 0
	var num_dps = 0
	
	# Temporary list to hold champions for the dungeon party
	var party_members = []

	# Debug: Print the current state of dungeon_party
	print("Starting Dungeon:", dungeon_name)
	print("Content of dungeon_party:", dungeon_party)

	# Calculate the total and average level of champions in the dungeon party
	var total_level = 0
	for champion in dungeon_party:
		total_level += champion.champion_xp_level
	
	var average_level = total_level / float(dungeon_party.size())
	
	print("Average Level: " + str(average_level))  # Debug print to check average level

	# Check if the average level meets the requirement
	if average_level < average_level_required:
		print("The average level of the party must be " + str(average_level_required) + " or more.")
		return  # Exit the function if the requirement is not met

	# Iterate through the dungeon party
	for champion in dungeon_party:
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
		elif champion.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Scholar", "Stalker"]:
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
			member.champion_status = "In " + dungeon_name
		
		# Create a new party button with a countdown timer
		var party_id = dungeon_name + "_Party_" + str(GlobalData.active_dungeon_parties.size() + 1)
		var party_button = Button.new()
		active_dungeon_party_container.add_child(party_button)
		
		var initial_time = dungeon_time * 60  # Convert minutes to seconds

		# Store the button in the dictionary for reference
		party_timers[party_id] = {"button": party_button}
		print("Added party to timers:", party_id, "with initial_time:", initial_time)  # Debug print to verify addition
		


		# Add the party to the GlobalData singleton with initial time and dungeon time
		GlobalData.add_party(party_id, party_members, initial_time, dungeon_time, dungeon_xp_reward, dungeon_copper_reward, dungeon_ilvl_reward, dungeon_power, minute_xp, minute_copper)
		
		# Remove the champions from the dungeon party
		for champion in party_members:
			if dungeon_party.has(champion):
				dungeon_party.erase(champion)
		update_dungeon_party_list()
		
		clear_container_children(dungeon_party_container)
		
		# Debug: Print the current state of the dictionaries
		print("Dungeon started. Active Dungeon Parties:", GlobalData.active_dungeon_parties)
		print("Dungeon started. Party Timers:", GlobalData.party_timers)
		
	else:
		print("Party composition does not meet requirements.")

func _on_map_update_timer_timeout():
	update_map_with_party_position(selected_dungeon)


func update_party_button_text(party_id):
	
	if not GlobalData.dungeon_parties.has(party_id):
		print("Party ID ", party_id, " is no longer active.")
		clear_container_children(active_dungeon_party_container)
		return
	
	var countdown_time = GlobalData.get_party_time(party_id)
	var dungeon_name = party_id.left(party_id.length() - 6)  # Remove last 6 characters


				
	# Check if the button exists and update its text
	if GlobalData.dungeon_timers[party_id].has("button"):
		var active_dungeon_button = GlobalData.dungeon_timers[party_id]["button"]
		if active_dungeon_button != null:
			# Update button text			
			var minutes = int(countdown_time / 60)
			var seconds = int(countdown_time % 60)
			var formatted_time = str("%02d:%02d" % [minutes, seconds])
			active_dungeon_button.text = party_id + " - " + formatted_time
			print("Updated button for dungeon party: ", party_id, " with time: ", formatted_time)
		else:
			# Create a new button if it doesn't exist
			active_dungeon_button = Button.new()
			active_dungeon_button.text = party_id  # Placeholder text; updated below
			active_dungeon_button.name = party_id
			active_dungeon_button.connect("pressed", Callable(self, "_on_active_raid_button_pressed").bind(party_id))
			active_dungeon_party_container.add_child(active_dungeon_button)
			active_dungeon_button.connect("pressed", func(): _on_active_dungeon_button_pressed(dungeon_name))
			var minutes = int(countdown_time / 60)
			var seconds = int(countdown_time % 60)
			var formatted_time = str("%02d:%02d" % [minutes, seconds])
			active_dungeon_button.text = party_id + " - " + formatted_time
			print("Recreated and updated button for dungeon party: ", party_id, " with time: ", formatted_time)
			# Store the new button reference in raid_timers
			GlobalData.dungeon_timers[party_id]["button"] = active_dungeon_button
			#print("Recreated raid button for:", raid_party_name)
	else:
		print("Error: Button reference not found for raid party:", party_id)
		clear_container_children(active_dungeon_party_container)

# Function called when timer times out
func _on_timer_timeout():
	for party_id in GlobalData.dungeon_timers.keys():
			update_party_button_text(party_id)
			return
	clear_container_children(active_dungeon_party_container)

func _on_start_dungeon_button_pressed():

	var dungeon_dropdown = get_node("CanvasLayer/Control/DungeonOptions")  # Adjust path if necessary
	var selected_dungeon_index = dungeon_dropdown.selected

	if selected_dungeon == "Idle":
		print("No dungeon selected")
		return  # No dungeon selected
	
	
	var selected_dungeon = dungeon_dropdown.get_item_text(selected_dungeon_index)
	print("Starting Dungeon: ", selected_dungeon)  # Debug statement
	
	if not dungeon_data.has(selected_dungeon):
		print("No valid dungeon selected.")
		return
	
	# Assuming the requirements are met
	var dungeon_name = selected_dungeon
	var dungeon_data = GlobalData.dungeons[dungeon_name]
	var dungeon_party_name = dungeon_name + "_party"
	var grid = dungeon_data["grid"]  # Retrieve the grid from the dungeon data	
	GlobalData.add_dungeon_party(dungeon_party_name, dungeon_party, grid) 

	for champion in dungeon_party:
		champion.champion_status = str("In raid: ", dungeon_name)
		print("Champion: ", champion.champion_name, " status changed to: ", champion.champion_status)
	


	if dungeon_name in GlobalData.dungeons:
		print("Starting dungeon: ", dungeon_name, " in dungeons_play_scene.")
		print("Sending to start global data startraid, which sends to DungeonManager:", dungeon_name)
		# Start the dungeon with the data
		GlobalData.start_dungeon(selected_dungeon)

		print("GlobalData start_dungeon and DungeonManager start_dungeon comepleted. Content of dungeon_party:", dungeon_party)
	
		# Generate the button for the ActiveRaidPartiesContainer
		var active_dungeon_button = Button.new()
		active_dungeon_button.text = dungeon_party_name
		active_dungeon_button.name = dungeon_party_name
		active_dungeon_button.connect("pressed", Callable(self, "_on_raid_button_pressed").bind(dungeon_party_name))
		active_dungeon_party_container.add_child(active_dungeon_button)
		active_dungeon_button.connect("pressed", func(): _on_active_dungeon_button_pressed(dungeon_name))
		
		
		
		# Update the button reference in the existing raid_timers entry
		if GlobalData.dungeon_timers.has(dungeon_party_name):
			GlobalData.dungeon_timers[dungeon_party_name]["button"] = active_dungeon_button
			print("Button created and stored in raid_timers for: ", dungeon_party_name)
		else:
			print("Error: Attempting to add a button for a raid timer that doesn't exist:", dungeon_party_name)

		# Debug print to check the state of raid_timers
		print("function on_start_raid_button_pressed: Updated raid_timers:", GlobalData.raid_timers)
		

	else:
		print("Dungeon not found in global data raids:", dungeon_name)	
	
	
	
	clear_container_children(dungeon_party_details_container)
	clear_container_children(dungeon_party_container)

#--------------------------------------------------------------------functions to drag and drop party members

# Variables to track dragged character
var dragged_character = null
var original_character_position = Vector2.ZERO





func _is_valid_role(champion_button, role):
	# Retrieve champion data from the button (assuming you have a way to get it)
	var champion_data = champion_button.champion_data  # Replace with actual way to get data

	if role == Role.TANK:
		return champion_data.champion_specialization in ["Defender", "Soldier", "Earth"]
	elif role == Role.HEALER:
		return champion_data.champion_specialization in ["Lightbringer", "Divine", "Water"]
	elif role == Role.DPS:
		return champion_data.champion_specialization in ["Berserker", "Voodoo", "Wind", "Fire", "Scholar", "Stalker"]

	return false

# Updated drag start function
func _on_character_drag_start(button):
	var button_global_position = button.get_global_rect().position
	var mouse_position = get_global_mouse_position()
	var offset = mouse_position - button_global_position
	original_character_position = button.position  # Store the local position
	dragged_character = button  # Assign button to dragged_character


# Function to handle character drag move
func _on_character_drag_move(position):
	if dragged_character:
		# Get the parent's global position
		var parent_global_position = dragged_character.get_parent().get_global_rect().position
		# Convert global position to local position relative to parent
		var local_position = position - parent_global_position - original_character_position
		# Update the position of the dragged character
		dragged_character.position = local_position

# Function to handle character drop
func _on_character_dropped(container, role):
	if dragged_character:
		if container.role == role:
			# Place character in the container
			dragged_character.position = container.position
			dragged_character = null
		else:
			# Revert character to original position
			dragged_character.position = original_character_position
			dragged_character = null

#------------ADD TO CRAWL PARTY FUNCTIONS-----------------------

func _on_slot_selected(slot_button):
	# Store the selected slot
	selected_slot = slot_button
	print("Selected slot:", selected_slot.name)
	
func _on_add_champion_to_crawl_party_pressed():
	if selected_champion and selected_slot:
		# Check if the champion is already in the formation
		var existing_slot = null
		
		# Search for the champion in the formation
		for slot_name in formation_data.keys():
			if formation_data[slot_name] == selected_champion:
				existing_slot = slot_name
				break
		
		if existing_slot:
			# Remove the champion from the formation
			formation_data.erase(existing_slot)
			print("Removed", selected_champion.champion_name, "from", existing_slot)

			# Reset the button text for the previous slot
			var previous_slot_button = crawler_party_grid.get_node(existing_slot)
			if previous_slot_button:
				previous_slot_button.text = existing_slot  # Reset to default position name
		else:
			# Assign the champion to the selected slot
			formation_data[selected_slot.name] = selected_champion
			print("Assigned", selected_champion.champion_name, "to", selected_slot.name)

			# Update button text with champion's name
			selected_slot.text = selected_champion.champion_name

		# Reset selection
		selected_champion = null
		selected_slot = null


func _on_start_crawl_button_pressed():
	var party_list = []
	var positions_list = []
	for slot_name in formation_data.keys():
		party_list.append(formation_data[slot_name])  # Add the champion
		positions_list.append(slot_name)  # Add the position
		# Send the full party data to GameManager
	GameManager.set_selected_party(party_list, positions_list)
	print("Starting Survivor Mode with party:", party_list)
	# Change to crawler world scene
	#get_tree().change_scene_to_file("res://crawler_world.tscn")
	if party_list:
		# Store dungeon parameters in GameManager
		GameManager.set_dungeon_parameters({
			"grid_width": 5,
			"grid_height": 5,
			"room_size": 20,
			"monster_level": dungeon_level,
			"difficulty": dungeon_difficulty,
			"theme": "ruins"
		})

		print("Starting Dungeon: ", GameManager.dungeon_parameters)
		
		# Load Crawler World
		get_tree().change_scene_to_file("res://crawler_world_3D.tscn")
	else:
		print("No champion selected!")

# Difficulty mapping (visible label -> internal value)
var difficulty_mapping = {
	"Normal": "normal",
	"Uncommon": "uncommon",
	"Rare": "rare",
	"Epic": "epic",
	"Legendary": "legendary"
}

var dungeon_level_mapping = {
	
}

func _on_difficulty_selected(index):
	# Update the selected difficulty
	var selected_text = dungeonDifficutlyButton.get_item_text(index)
	dungeon_difficulty = difficulty_mapping[selected_text]
	
	print("🏆 Dungeon Difficulty Set to: ", dungeon_difficulty)

func _populate_dungeon_level_dropdown():
	dungeonLevelButton.clear()
	for i in range(1, 61):
		dungeonLevelButton.add_item(str(i))  # shows “1”, “2”, ..., “60”
	# Limit popup height (shows about 10 items at once)
	var popup = dungeonLevelButton.get_popup()
	popup.max_size = Vector2i(250, 250)  # pixels

func _on_dungeon_level_selected(index):
	dungeon_level = index + 1  # because add_item() starts from 0
	print("💀 Dungeon Level Set to: ", dungeon_level)


func _on_inspect_champion_button_button_down() -> void:
	if selected_champion:
		championPanel.open(selected_champion)
	else:
		print("Select a champion to inspect.")
		pass
		
