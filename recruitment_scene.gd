extends Node2D



var background_node
var parallax_factor = 0.05  # Adjust this value to control the strength of the parallax effect
var spring_factor = 0.05  # Adjust this value to control the strength of the spring effect
var viewport_size

var change_name_dialog
var generated_champions = []
var guild_roster = [] # List to store champions in the guild roster
var champion_id_counter = 0
var champion_ui_container
var champion_details_container
var roster_list # Reference to UI element displaying the guild roster
var selected_champion # Declare a variable to store the currently selected champion
var add_to_roster_button
var remove_from_roster_button
var inspect_champion_button
#var global_data_instance
#var global_data_node

# Preload the Character scene
var CharacterScene = preload("res://character.tscn")

# Constants
const NUM_STATS = 6

# Reference to the TileMap and its tileset
var GeneralRaidTileMap: TileMap
var tile_set: TileSet

#double click tracker
var last_click_time = 0.0
const DOUBLE_CLICK_INTERVAL = 0.3  # Max time (in seconds) between clicks to register as double-click


# Atlas coordinates for specialization symbols
var specialization_atlas_coords = {
	"TANK": Vector2i(7, 0),   # Tile at (7, 0)
	"Soldier": Vector2i(7, 0),
	"Defender": Vector2i(7, 0),
	"Earth": Vector2i(7, 0),
	"HEALER": Vector2i(8, 0), # Tile at (8, 0)
	"Lightbringer": Vector2i(8, 0),
	"Divine": Vector2i(8, 0),
	"Water": Vector2i(8, 0),
	"DPS": Vector2i(6, 0),    # Tile at (6, 0)
	"Berserker": Vector2i(6, 0),
	"Voodoo": Vector2i(6, 0),
	"Wind": Vector2i(6, 0),
	"Fire": Vector2i(6, 0),
	"Necromancer": Vector2i(6, 0),
	"Stalker": Vector2i(6, 0)
}


# Stat coefficients based on class and specialization
var stat_coefficients = {
	"Rogue": {
		"Stalker": {"Offense": 0.14, "Defense": 0.07, "Teamwork": 0.1, "Reflexes": 0.11, "Endurance": 0.11, "Focus": 0.1},
		# Add other specializations if needed
	},
	"Priest": {
		"Divine": {"Offense": 0.1, "Defense": 0.13, "Teamwork": 0.1, "Reflexes": 0.11, "Endurance": 0.1, "Focus": 0.11},
		"Voodoo": {"Offense": 0.13, "Defense": 0.08, "Teamwork": 0.1, "Reflexes": 0.1, "Endurance": 0.1, "Focus": 0.1},
		# Add other specializations if needed
	},
	"Fighter": {
		"Soldier": {"Offense": 0.08, "Defense": 0.13, "Teamwork": 0.11, "Reflexes": 0.1, "Endurance": 0.1, "Focus": 0.13},
		"Berserker": {"Offense": 0.13, "Defense": 0.08, "Teamwork": 0.1, "Reflexes": 0.11, "Endurance": 0.1, "Focus": 0.11},
	},
	"Crusader": {
		"Defender": {"Offense": 0.08, "Defense": 0.13, "Teamwork": 0.11, "Reflexes": 0.12, "Endurance": 0.1, "Focus": 0.12},
		"Lightbringer": {"Offense": 0.08, "Defense": 0.13, "Teamwork": 0.12, "Reflexes": 0.11, "Endurance": 0.1, "Focus": 0.12},
	},
	"Shaman": {
		"Water": {"Offense": 0.08, "Defense": 0.13, "Teamwork": 0.12, "Reflexes": 0.11, "Endurance": 0.1, "Focus": 0.12},
		"Fire": {"Offense": 0.13, "Defense": 0.08, "Teamwork": 0.09, "Reflexes": 0.1, "Endurance": 0.1, "Focus": 0.1},
		"Earth": {"Offense": 0.08, "Defense": 0.13, "Teamwork": 0.12, "Reflexes": 0.11, "Endurance": 0.1, "Focus": 0.12},
		"Wind": {"Offense": 0.13, "Defense": 0.08, "Teamwork": 0.09, "Reflexes": 0.1, "Endurance": 0.1, "Focus": 0.1},
	},
	"Wizard": {
		"Necromancer": {"Offense": 0.14, "Defense": 0.07, "Teamwork": 0.11, "Reflexes": 0.1, "Endurance": 0.11, "Focus": 0.1},
	},
	# Add other classes and specializations as needed
}



	
func _ready():
	print("Tween class name: ", Tween)

	background_node = get_node("Node2D/Background")
	print(background_node)
	var global_background_manager = GlobalBackgroundManager.new()
	background_node.texture = global_background_manager.get_background("recruitment")
	viewport_size = get_viewport_rect().size
	
	var background_texture_size = background_node.texture.get_size()
	var scale = viewport_size / background_texture_size
	background_node.scale = scale * 1.2
	
	
	print("Recruitment scene ready!")
	# Find the champion_ui_container node by name
	champion_ui_container = get_node("CanvasLayer/Control/ChampionUIContainer")
	champion_details_container = get_node("CanvasLayer/Control/ChampionDetailsContainer")
	roster_list = get_node("CanvasLayer/Control/GuildRosterContainer")
	add_to_roster_button = get_node("CanvasLayer/Control/AddToGuildRoster")
	remove_from_roster_button = get_node("CanvasLayer/Control/RemoveFromGuildRoster")
	inspect_champion_button = get_node("CanvasLayer/Control/InspectChampionButton")
	change_name_dialog = get_node("CanvasLayer/Control/ChangeNameWindow")
	GeneralRaidTileMap = get_node("CanvasLayer/Control/GeneralRaidTileMap")  # Replace with the correct path
	tile_set = GeneralRaidTileMap.tile_set

	show_global_roster_list()

func _process(delta):
	var viewport_center = viewport_size / 2
	
	# Get the mouse position relative to the center of the viewport
	var mouse_position = get_global_mouse_position()
	var mouse_offset = mouse_position - viewport_center
	
	# Calculate the movement for the background image
	var target_position = -mouse_offset * parallax_factor
	
	# Apply spring effect to move background towards target position
	background_node.position = background_node.position.lerp(target_position, spring_factor)
	
	# Clamp the background image position to keep it within bounds
	background_node.position.x = clamp(background_node.position.x, -viewport_size.x * 0.1, viewport_size.x * 0.1)
	background_node.position.y = clamp(background_node.position.y, -viewport_size.y * 0.1, viewport_size.y * 0.1)

func clear_container_children(container):
	#for child in container.get_children():
	# Clear the container by removing its children
	while container.get_child_count() > 0:
		var child = container.get_child(0)
		container.remove_child(child)
		child.queue_free()

func _on_go_to_guild_house_pressed():
	
	get_tree().change_scene_to_file("res://guild_house.tscn")


func _on_go_to_roster_pressed():
	get_tree().change_scene_to_file("res://guild_roster_scene.tscn")
	

#------------------------------------------------------------------------------GENERATE CHAMPIONS

func _on_generate_champions_button_pressed():
	_generate_champions()
	
func _generate_champions():
	print("Generating 10 unsullied souls...")
	generated_champions.clear()
	clear_container_children(champion_ui_container)

	# Generate 10 champions
	for i in range(10):
		var new_champion = Champion.new()
		new_champion.champion_name = generate_unique_name()
		new_champion.champion_race = get_random_race()
		new_champion.champion_class = get_random_class()
		#new_champion.champion_specialization
		new_champion.champion_xp = 0
		new_champion.champion_xp_level = calculate_level(new_champion.champion_xp)
		new_champion.champion_item_level = 1
		new_champion.champion_status
		new_champion.champion_morale

	# Roll for rarity
		var rarity_roll = randf()
		if rarity_roll <= 0.4:  # Common (40% chance)
			new_champion.champion_rarity = "Common"
			new_champion.champion_skill = randi_range(1, 40)
		elif rarity_roll <= 0.7:  # Uncommon (30% chance)
			new_champion.champion_rarity = "Uncommon"
			new_champion.champion_skill = randi_range(20, 60)
			new_champion.profession_skill = ["Leatherworker", "Tailor", "Blacksmith"][randi() % 3]
		elif rarity_roll <= 0.9:  # Rare (20% chance)
			new_champion.champion_rarity = "Rare"
			new_champion.champion_skill = randi_range(40, 80)
			if randf() <= 0.25: # 25% chance to get skillful	
				new_champion.skillful_skill = get_random_skillful_skill(new_champion.champion_class)
			new_champion.profession_skill = ["Leatherworker", "Tailor", "Blacksmith", "Alchemist"][randi() % 4]
		elif rarity_roll <= 0.99:  # Epic (9% chance)
			new_champion.champion_rarity = "Epic"
			new_champion.champion_skill = randi_range(70, 95)
			#if randf() <= 0.1:  # 10% chance for class leader
				#new_champion.class_leader_skill = get_random_class_leader_skill(new_champion.class)
			if randf() <= 0.50: # 50% chance to get skillful	
				new_champion.skillful_skill = get_random_skillful_skill(new_champion.champion_class)
			new_champion.profession_skill = ["Leatherworker", "Tailor", "Blacksmith", "Alchemist", "Enchanter"][randi() % 5]
		else:  # Legendary (1% chance)
			new_champion.champion_rarity = "Legendary"
			new_champion.champion_skill = randi_range(85, 100)
			#if randf() <= 0.1:  # 10% chance for raid leader
				#new_champion.raid_leader_skill = get_random_raid_leader_skill()
			#elif randf() <= 0.5:  # 50% chance for class leader
				#new_champion.class_leader_skill = get_random_class_leader_skill(new_champion.class)
			new_champion.skillful_skill = get_random_skillful_skill(new_champion.champion_class)
			new_champion.profession_skill = ["Leatherworker", "Tailor", "Blacksmith", "Alchemist", "Enchanter"][randi() % 5]
		
	# Add guild leader skill with 1% chance for every rarity
		#if randf() <= 0.01:
			#new_champion.guild_leader_skill = get_random_guild_leader_skill()
	

#--------------------------------------------------------------------------------END RARITY ROLL


		# Generate random champion traits
		#new_champion.champion_skill = randi() % 100 + 1  # Random skill value between 1 and 100

		
		
		# Add champion to the list
		generated_champions.append(new_champion)

		# Create a button for the champion and add it to the UI container
		var champion_button = Button.new()
		champion_button.text = new_champion.champion_name + " (" + str(new_champion.champion_xp_level) + ")"
		champion_button.connect("pressed", func(): _on_champion_button_pressed(new_champion))
		#print(generated_champions)

		# Set background color based on champion's class
		match new_champion.champion_class:
			"Rogue":
				champion_button.modulate = Color("#FFF468")
			"Priest":
				champion_button.modulate = Color("#FFFFFF")
			"Fighter":
				champion_button.modulate = Color("#C69B6D")
			"Crusader":
				champion_button.modulate = Color("#F48CBA")
			"Shaman":
				champion_button.modulate = Color("#0070DD")
			"Wizard":
				champion_button.modulate = Color("#8788EE")
			_:
			# Default color if champion class is not recognized
				champion_button.modulate = Color(1, 1, 1) # White
		
				# Print class and specialization to debug

				

		
		# Assign specialization based on class
		match new_champion.champion_class:
			"Fighter":
				new_champion.champion_specialization = ["Soldier", "Berserker"][randi() % 2]
			"Crusader":
				new_champion.champion_specialization = ["Defender", "Lightbringer"][randi() % 2]
			"Priest":
				new_champion.champion_specialization = ["Divine", "Voodoo"][randi() % 2]
			"Shaman":
				new_champion.champion_specialization = ["Water", "Earth", "Wind", "Fire"][randi() % 4]
			"Wizard":
				new_champion.champion_specialization = "Necromancer"
			"Rogue":
				new_champion.champion_specialization = "Stalker"
			_:
				# Handle unrecognized class
				new_champion.champion_specialization = "Unknown"

		print("Class: ", new_champion.champion_class, " Specialization: ", new_champion.champion_specialization)

			# Create a TextureRect for the specialization symbol
		var symbol_texture_rect = TextureRect.new()
		symbol_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		symbol_texture_rect.custom_minimum_size = Vector2(16, 16)  # Adjust as needed
		symbol_texture_rect.self_modulate = Color(1, 1, 1, 1)  # Explicitly ensure the texture is unaffected
		symbol_texture_rect.z_index = 1 # Ensure the symbol renders above the button background
		
		   # Find the correct atlas coordinates for the champion's specialization
		var specialization = new_champion.champion_specialization
		if specialization_atlas_coords.has(specialization):
			var atlas_coords = specialization_atlas_coords[specialization]
					# Create an AtlasTexture for the symbol
			var symbol_texture = AtlasTexture.new()
			symbol_texture.atlas = tile_set.get_source(0).texture  # Assuming source ID 0
			symbol_texture.region = Rect2(
				atlas_coords.x * 16, atlas_coords.y * 16,  # Tile position in pixels
				16, 16  # Tile size in pixels
			)
			symbol_texture_rect.texture = symbol_texture
			new_champion.specialization_texture = symbol_texture
		else:
			print("Warning: No symbol found for specialization ", specialization)

	# Add the TextureRect as a child to the button
		champion_button.add_child(symbol_texture_rect)
		symbol_texture_rect.position = Vector2(champion_button.size.x + 200, 10)

		
		 # Generate random stats based on overall skill
		var overall_rating = new_champion.champion_skill
		var champion_stats = generate_champion_with_weights(new_champion.champion_skill, new_champion.champion_class, new_champion.champion_specialization)
		if champion_stats != null:
			new_champion.champion_teamwork_rating = champion_stats["Teamwork"]
			new_champion.champion_reflexes_rating = champion_stats["Reflexes"]
			new_champion.champion_offense_rating = champion_stats["Offense"]
			new_champion.champion_defense_rating = champion_stats["Defense"]
			new_champion.champion_endurance_rating = champion_stats["Endurance"]
			new_champion.champion_focus_rating = champion_stats["Focus"]
		else:
			print("Warning: Generated champion stats are null for ", new_champion.champion_class, " with specialization ", new_champion.champion_specialization)
		
		

		champion_ui_container.add_child(champion_button)

# Generate a champion with weighted random stats based on overall rating and class/specialization
func generate_champion_with_weights(overall_rating, champion_class, champion_specialization):
	
	if not stat_coefficients.has(champion_class):
		print("Error: Class not found in stat_coefficients: ", champion_class)
		return null
	if not stat_coefficients[champion_class].has(champion_specialization):
		print("Error: Specialization not found in stat_coefficients for class ", champion_class, ": ", champion_specialization)
		return null
	
	
	var total_points = overall_rating * NUM_STATS
	var coefficients = stat_coefficients[champion_class][champion_specialization]
	var weights = [coefficients["Teamwork"], coefficients["Reflexes"], coefficients["Offense"], coefficients["Defense"], coefficients["Endurance"], coefficients["Focus"]]
	var stat_values = weighted_randomize_stats(total_points, weights)
	
	var champion_stats = {
		"Teamwork": stat_values[0],
		"Reflexes": stat_values[1],
		"Offense": stat_values[2],
		"Defense": stat_values[3],
		"Endurance": stat_values[4],
		"Focus": stat_values[5]
	}
	
	return champion_stats

func _on_champion_button_pressed(champion):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_click_time < DOUBLE_CLICK_INTERVAL:
		_on_champion_button_double_pressed(champion)
	else:
		_on_champion_button_single_pressed(champion)
	last_click_time = current_time

# Function to handle champion button press
func _on_champion_button_single_pressed(champion):
	# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	print(champion.champion_specialization)
	update_champion_details(champion)
	selected_champion = champion

# Function to handle champion button press
func _on_champion_button_double_pressed(champion):
	# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	print(champion.champion_specialization)
	update_champion_details(champion)
	selected_champion = champion
	add_to_roster(selected_champion)
	update_roster_list()


# Function to Randomize stats with weights to sum up to a total rating
func weighted_randomize_stats(total_points, weights):
	var stats = []
	var remaining_points = total_points
	var weight_sum = 0.0
	for weight in weights:
		weight_sum += weight
	
	# Initial distribution
	for i in range(NUM_STATS):
		var weight = weights[i] / float(weight_sum)
		var stat = int(weight * total_points)
		stat = min(stat, 100)  # Ensure stat does not exceed 100
		stats.append(stat)
		remaining_points -= stat
	
	# Distribute remaining points proportionally
	while remaining_points > 0:
		for i in range(NUM_STATS):
			if remaining_points <= 0:
				break
			var weight = weights[i] / float(weight_sum)
			var add_points = min(1, remaining_points)  # Add points one by one to avoid overshooting
			if stats[i] + add_points <= 100:
				stats[i] += add_points
				remaining_points -= add_points

	return stats

func update_champions_ui_container():
	 # Clear the list content
	clear_container_children(champion_ui_container)
	
	#GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in generated_champions:
		#var champion_roster_button = Button.new()
		var recruited_champ_button = champion.create_champion_button(champion)
		#champion_roster_button.text = champion.champion_name + " (" + str(champion.champion_xp_level) + ")"
		recruited_champ_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		#set_button_color(champion_roster_button, champion.champion_rarity)
		
				# Set background color based on champion's class
	#	match champion.champion_class:
	#		"Rogue":
	#			champion_roster_button.modulate = Color("#FFF468")
	#		"Priest":
	#			champion_roster_button.modulate = Color("#FFFFFF")
	#		"Fighter":
	#			champion_roster_button.modulate = Color("#C69B6D")
	#		"Crusader":
	#			champion_roster_button.modulate = Color("#F48CBA")
	#		"Shaman":
	#			champion_roster_button.modulate = Color("#0070DD")
	#		"Wizard":
	#			champion_roster_button.modulate = Color("#8788EE")
	#		_:
			# Default color if champion class is not recognized
	#			champion_roster_button.modulate = Color(1, 1, 1) # White
		
		champion_ui_container.add_child(recruited_champ_button)
		GlobalData.update_hud()
		

	#generated_champions.clear()
	#clear_container_children(champion_ui_container)
	
	
	
# Function to update the roster list UI element
func update_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	
	GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		
		var champion_roster_button = champion.create_champion_button(champion)

		#champion_roster_button.text = champion.champion_name + " (" + str(champion.champion_xp_level) + ")"
		
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		#set_button_color(champion_roster_button, champion.champion_rarity)
		
				# Set background color based on champion's class
		#match champion.champion_class:
		#	"Rogue":
		#		champion_roster_button.modulate = Color("#FFF468")
		#	"Priest":
		#		champion_roster_button.modulate = Color("#FFFFFF")
		#	"Fighter":
		#		champion_roster_button.modulate = Color("#C69B6D")
		#	"Crusader":
		#		champion_roster_button.modulate = Color("#F48CBA")
		#	"Shaman":
		#		champion_roster_button.modulate = Color("#0070DD")
		#	"Wizard":
		#		champion_roster_button.modulate = Color("#8788EE")
		#	_:
			# Default color if champion class is not recognized
		#		champion_roster_button.modulate = Color(1, 1, 1) # White
		
		roster_list.add_child(champion_roster_button)
		GlobalData.update_hud()
		

# Function to set button color based on rarity
func set_button_color(champion_roster_button, champion_rarity):
	var border_color
	match champion_rarity:
		"Common":
			border_color = Color("#FFFFFF")  # White border for Common
		"Uncommon":
			border_color = Color("#00FF00")  # Green border for Uncommon
		"Rare":
			border_color = Color("#0000FF")  # Blue border for Rare
		"Epic":
			border_color = Color("#800080")  # Purple border for Epic
		"Legendary":
			border_color = Color("#FFA500")  # Orange border for Legendary

	# Create a StyleBoxFlat with the desired border color
	var stylebox = StyleBoxFlat.new()
	stylebox.border_color = border_color
	stylebox.border_width = 2  # Adjust border width as needed

	# Add the StyleBoxFlat override to the button
	champion_roster_button.add_stylebox_override("normal", stylebox)


func show_global_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	print("Show global roster list function called")

	# Retrieve guild roster data from the global script
	guild_roster = GlobalData.get_guild_roster()
	
	#print(guild_roster)	

	
	# Add champions in the guild roster to the roster list
	#for champion in guild_roster:
	#	var champion_roster_button = Button.new()
	#	champion_roster_button.text = champion.champion_name + " (" + str(champion.champion_xp_level) + ")"
	#	champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		
				# Set background color based on champion's class
	#	match champion.champion_class:
	#		"Rogue":
	#			champion_roster_button.modulate = Color("#FFF468")
	#		"Priest":
	#			champion_roster_button.modulate = Color("#FFFFFF")
	#		"Fighter":
	#			champion_roster_button.modulate = Color("#C69B6D")
	#		"Crusader":
	#			champion_roster_button.modulate = Color("#F48CBA")
	#		"Shaman":
	#			champion_roster_button.modulate = Color("#0070DD")
	#		"Wizard":
	#			champion_roster_button.modulate = Color("#8788EE")
	#		_:
	#		# Default color if champion class is not recognized
	#			champion_roster_button.modulate = Color(1, 1, 1) # White
		
	#	roster_list.add_child(champion_roster_button)	
	for champion in guild_roster:
		var champion_button = champion.create_champion_button(champion)
		champion_button.connect("gui_input", func(event): 
			if event is InputEventMouseButton and event.pressed:
				_on_champion_button_pressed(champion)
		)
	
		roster_list.add_child(champion_button)

# Function to add a champion to the guild roster
func add_to_roster(champion):
	 # Check if the champion already exists in the guild roster
	if guild_roster.find(champion) == -1:
		# If the champion doesn't exist, add it to the roster
		guild_roster.append(champion)
	
		update_roster_list()
		
		if generated_champions.find(champion) != -1:
			print("Removing champion: ", champion.champion_name)
			generated_champions.erase(champion)
		else:
			print("Champion not found in generated_champions")
			
		update_champions_ui_container()	
		
		add_champion_avatar(champion)

	else:
		print("Champion already exists in the guild roster")
		# Show a dialog window prompt indicating that the champion already exists
		#$PopupDialog.label.text = "Champion already exists in the guild roster"
		#$PopupDialog.popup_centered() # Show the dialog window at the center of the screen


func remove_from_roster(champion):
		guild_roster.erase(champion)
		update_roster_list() # Update the roster list UI after removal



# Function to update the champion details container
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
	var lbl_skillful = champion_details_container.get_node("lblSkillful")
	var lbl_race = champion_details_container.get_node("lblRace")
	var lbl_level = champion_details_container.get_node("lblLevel")
	var lbl_itemlvl = champion_details_container.get_node("lblItemlvl")
	var lbl_status = champion_details_container.get_node("lblStatus")
	var lbl_rarity = champion_details_container.get_node("lblRarity")
	var lbl_proffession = champion_details_container.get_node("lblProffession")
	var lbl_teamwork = champion_details_container.get_node("lblTeamWork")
	var lbl_reflexes = champion_details_container.get_node("lblReflexes")
	var lbl_offense = champion_details_container.get_node("lblOffense")
	var lbl_defense = champion_details_container.get_node("lblDefense")
	var lbl_endurance = champion_details_container.get_node("lblEndurance")
	var lbl_focus = champion_details_container.get_node("lblFocus")
	var lbl_morale = champion_details_container.get_node("lblMorale")

	lbl_name.text = "Name: " + champion.champion_name
	lbl_class.text = "Class: " + champion.champion_class
	lbl_spec.text = "Spec: " + champion.champion_specialization
	lbl_skill.text = "Skill level: " + str(champion.champion_skill) + " (" + skill_label + ")"
	lbl_skillful.text = "Skillful: " + champion.skillful_skill
	lbl_race.text = "Race: " + champion.champion_race
	lbl_level.text = "Level: " + str(champion.champion_xp_level)
	lbl_itemlvl.text = "Item level: " + str(champion.champion_item_level)
	lbl_status.text = "Status: " + champion.champion_status
	lbl_rarity.text = "Rarity: " + champion.champion_rarity
	lbl_proffession.text = "Proffession: " + champion.profession_skill
	lbl_teamwork.text = "TW rating: " + str(champion.champion_teamwork_rating)
	lbl_reflexes.text = "RFLX rating: " + str(champion.champion_reflexes_rating)
	lbl_offense.text = "OFF rating: " + str(champion.champion_offense_rating)
	lbl_defense.text = "DEF rating: " + str(champion.champion_defense_rating)
	lbl_endurance.text = "END rating: " + str(champion.champion_endurance_rating)
	lbl_focus.text = "FOC rating: " + str(champion.champion_focus_rating)
	lbl_morale.text = "Morale: " + str(champion.champion_morale)
	
#function to get skillful skill
func get_random_skillful_skill(champion_class: String) -> String:
	var skillful_skills = {
		"Fighter": ["Skillful_Tank", "Skillful_Melee_DPS"],
		"Crusader": ["Skillful_Tank", "Skillful_Healer"],
		"Priest": ["Skillful_Healer", "Skillful_Ranged_DPS"],
		"Shaman": ["Skillful_Tank", "Skillful_Melee_DPS", "Skillful_Ranged_DPS", "Skillful_Healer"],
		"Wizard": ["Skillful_Ranged_DPS"],
		"Rogue": ["Skillful_Melee_DPS"]
	}
	
	# Check if the champion class exists in the skillful_skills dictionary
	if skillful_skills.has(champion_class):
		var possible_skills = skillful_skills[champion_class]
		return possible_skills[randi() % possible_skills.size()]
	else:
		print("Class not found in skillful_skills:", champion_class)
		return ""  # Return an empty string if the class is not found

# Function to get a random race
func get_random_race():
	var races = ["Human", "Dwarf", "Elf", "Orc", "Undead", "Halfling"]
	return races[randi() % races.size()]

# Function to get a random class
func get_random_class():
	var classes = ["Fighter", "Crusader", "Priest", "Shaman", "Wizard", "Rogue"]
	return classes[randi() % classes.size()]

# Function to generate a unique ID for champions
func get_unique_champion_id():
	champion_id_counter += 1
	return champion_id_counter
	
# Function to generate a unique name for champions
func generate_unique_name():
	var prefix = "Champion"
	var random_letters = generate_random_letters(3)
	return prefix + random_letters

# Function to generate a specified number of random uppercase letters
func generate_random_letters(count):
	var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var result = ""
	
	for i in range(count):
		var random_index = randi() % letters.length()
		result += letters.substr(random_index, 1)
	
	return result

func _on_clear_champion_list_pressed():
	clear_container_children(champion_ui_container)


func _on_add_to_guild_roster_pressed():
	if selected_champion:
		add_to_roster(selected_champion)
		update_roster_list()
	else: print("No selected champion")



func _on_remove_from_guild_roster_pressed():
	if selected_champion:
		print("Removing champion:", selected_champion.champion_name)
		#print(guild_roster)
		remove_from_roster(selected_champion)
	else: print("No selected champion")
	





# ------------------------------------------------------------------------- XP grejer --------------

# Function to calculate the current level based on XP
func calculate_level(xp: int) -> int:
	var level = 0
	for i in range(xp_thresholds.size()):
		if xp < xp_thresholds[i]:
			break
		level += 1
	return level
	
# Function to update champion's XP when they complete activities
func add_xp_to_champion(champion, xp_gained: int):
	champion.champion_xp += xp_gained
	var new_level = calculate_level(champion.champion_xp)
	if new_level > champion.champion_xp_level:
		champion.champion_xp_level = new_level
		print(selected_champion.champion_name, " is now level", new_level)

# Define XP thresholds for each level
var xp_thresholds = [
	0, 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500,
	7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300,
	23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44100,
	46800, 49600, 52500, 55500, 58600, 61700, 64900, 68200, 71600, 75100,
	78700, 82400, 86100, 90000, 94000, 98100, 102300, 106600, 111000, 115500,
	120100, 124800, 129600, 134500, 139500, 144600, 149800, 155100, 160500, 166000,
	171600, 177300, 183100, 189000, 195000, 201000, 207100, 213300, 219600
]
# XP test button
func _on_give_xp_pressed():
	if selected_champion:
		print(selected_champion.champion_name, " was given 100 000 XP")
		GlobalData.add_xp_to_champion(selected_champion, 100000)
		selected_champion.champion_item_level += 100
		print(selected_champion.champion_name, " item level increased to ", selected_champion.champion_item_level)
		selected_champion.calculate_champion_power()
		print(selected_champion.champion_name, " now has a Champion Power of ", selected_champion.champion_power)
		update_champion_details(selected_champion)
		update_roster_list()
	else:
		pass


func _on_give_xp_to_guild_pressed():
#	ChampionManager.close_champion_panel()
	for champion in guild_roster:
		selected_champion = champion
		print(selected_champion.champion_name, " was given 100 000 XP")
		GlobalData.add_xp_to_champion(selected_champion, 100000)
		selected_champion.champion_item_level += 100
		print(selected_champion.champion_name, " item level increased to ", selected_champion.champion_item_level)
		selected_champion.calculate_champion_power()
		print(selected_champion.champion_name, " now has a Champion Power of ", selected_champion.champion_power)
		update_champion_details(selected_champion)
	update_roster_list()


#func _on_inspect_champion_button_pressed(champion: Champion):
#	print("Button pressed to inspect champion: ", champion.champion_name)
	#ChampionManager.open_champion_panel(champion)

func _on_inspect_champion_button_pressed():
	if selected_champion:
		print("Opening panel for: ", selected_champion.champion_name)
		ChampionManager.open_champion_panel(selected_champion)
	else:
		print("No champion selected!")

# Getter function for selected_champion
func get_selected_champion():
	return selected_champion
	
# --------------------------------------------------------------------------- Champion graphics

func add_champion_avatar(champion_data):
	# Create a new instance of the Character scene
	var new_champion_avatar = CharacterScene.instantiate()
	print("New champion instance: ", new_champion_avatar)

	$ChampionAvatarArea.add_child(new_champion_avatar)

	# Get screen size
	var screen_size = get_viewport().get_visible_rect().size
	var lower_third_bounds = Rect2(Vector2(0, screen_size.y * 2 / 3), Vector2(screen_size.x, screen_size.y / 3))
	print("Lower third bounds: ", lower_third_bounds)

	new_champion_avatar.position = Vector2(500, 800)  # Default position within viewport

	# Set movement bounds
	new_champion_avatar.set_movement_bounds(lower_third_bounds)
	print("Movement bounds set for champion.")

	# Pass data for customization

	#new_champion_avatar.get_node("Skeleton2D/Body").texture = preload("res://textures/default_character.png")
	#new_champion_avatar.get_node("Skeleton2D/Armor").texture = preload("res://textures/armour1.png")

	# Add the champion to the GuildArea

	#print("ChampionAvatarArea global position: ", $ChampionAvatarArea.global_position)

	#get_tree().root.add_child(new_champion_avatar)
	# Check if nodes are found before assigning textures
	new_champion_avatar.set_champion_data(champion_data)
	print("Champion data set: ", champion_data)
	
	#var body_node = new_champion_avatar.get_node("Skeleton2D/Body")
	#var armor_node = new_champion_avatar.get_node("Skeleton2D/Armor")

	#if body_node and armor_node:
	#	print("Body node found: ", body_node)
	#	print("Armor node found: ", armor_node)

	# Assign textures
#		body_node.texture = preload("res://textures/default_character.png")
#		armor_node.texture = preload("res://textures/armour1.png")
#		print("Body texture after manual assignment: ", body_node.texture)
#		print("Armor texture after manual assignment: ", armor_node.texture)
#	else:
#		print("Body or Armor node not found.")
	
	
	print("Is visible: ", new_champion_avatar.visible)
	
	print("Added Champion Avatar for : ", champion_data.champion_name)
	print("Champion position: ", new_champion_avatar.position)
	print("Body texture: ", new_champion_avatar.get_node("Skeleton2D/Root/Torso/Body").texture)
	print("Armor texture: ", new_champion_avatar.get_node("Skeleton2D/Root/Torso/Armor").texture)
#	print_tree()



#-------------------- -------------------------CHANGE NAME ON CHAMPION 

func _on_change_champion_name_pressed():
	change_name_dialog.visible = true


func _on_button_cancel_pressed():
	# Close the change name dialog window
	change_name_dialog.visible = false

func _on_button_save_name_pressed():
	if selected_champion != null:
		# Retrieve the new name from the LineEdit node in the dialog window
		var new_name = change_name_dialog.get_node("Control/LineEdit").text
		# Save the new name to the selected champion
		selected_champion.champion_name = new_name
		# Update the UI to reflect the new name
		update_champion_details(selected_champion)
		update_roster_list()
		change_name_dialog.visible = false


func _on_change_name_window_close_requested() -> void:
	change_name_dialog.visible = false
