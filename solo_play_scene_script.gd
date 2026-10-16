extends CanvasLayer

var guild_roster = [] # List to store champions in the guild roster
var roster_list # Reference to UI element displaying the guild roster
var selected_champion # Declare a variable to store the currently selected champion
var champion_details_container
#var global_data_node
var activity_dropdown

# Define a variable to track elapsed time
var print_timer: float = 61
var print_interval: float = 60  # Print every 60 seconds
var start_crawl_button

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Solo Play scene ready!")
	champion_details_container = get_node("Control/ChampionDetailsContainer")
	roster_list = get_node("Control/GuildRosterContainer")
	#global_data_node = get_node("/root/GlobalData")
	start_crawl_button = get_node("Control/StartCrawlButton")
	# Access the DropdownMenu node using its path
	activity_dropdown = get_node("Control/ActivityOptions")
	# List of activity options
	var activity_options = ["Idle", "Solo Questing", "Activity 2", "Activity 3"]
	# Add activity options to the dropdown menu
	add_activity_options(activity_options)
	
	show_global_roster_list()
	
	#background image stuff
	var background_node = get_node("Node2D/Background")
	print(background_node)
	var global_background_manager = GlobalBackgroundManager.new()
	#global_background_manager = GlobalBackgroundManager.get_instance()
	background_node.texture = global_background_manager.get_background("solo_play_scene")
	
	var viewport_size = background_node.get_viewport_rect().size
	var background_texture_size = background_node.texture.get_size()
	var scale = viewport_size / background_texture_size
	background_node.scale = scale
	
	 # Calculate the position to center the background
	var position = viewport_size / 2
	# Set the position of the background node
	background_node.position = position
#func _process(delta: float):
	#get_node("/root/GlobalData").process_champion_xp(delta)


# Function to add activity options to the dropdown menu
func add_activity_options(options):
	# Clear existing items in the dropdown menu
	activity_dropdown.clear()

	# Add each activity option as a new item in the dropdown menu
	for option in options:
		activity_dropdown.add_item(option)


func _on_activity_options_item_selected(index):
	print("menu selected")
	if selected_champion != null:
	# Get the selected activity option
		var selected_activity = get_node("Control/ActivityOptions").get_item_text(index)
	# Perform actions based on the selected activity
		match selected_activity:
			"Idle":
				stop_activity(selected_champion)
			"Solo Questing":
				start_solo_questing(selected_champion)
			"Activity 2":
				pass
				# Handle Activity 2
			"Activity 3":
				pass
			# Handle Activity 3
		# Add more cases as needed
		update_champion_details(selected_champion)
	else: 
		print("Please select a champion.")

# Function to start an activity for a champion
func start_solo_questing(champion):
	
	if selected_champion != null:
	# Check if the champion is already engaged in an activity
		if champion.champion_status != "Idle":
			print(champion.champion_name + " is already busy!")
			return
	# Set the champion's status to the name of the activity
		champion.champion_status = "Solo Questing"  # Or the name of the specific activity
	else:
		print("Please select a Champion!")
		return
	
	

# Function to stop an activity for a champion
func stop_activity(champion):
	# Check if the champion is currently engaged in an activity
	if champion.champion_status != "Idle":
		# Stop any ongoing activity-related actions, such as timers
		# Reset the champion's status to "Idle"
		champion.champion_status = "Idle"
	else:
		print(champion.champion_name + " is already idle!")

#------champ list stuff----------

func clear_container_children(container):
	#for child in container.get_children():
	# Clear the container by removing its children
	while container.get_child_count() > 0:
		var child = container.get_child(0)
		container.remove_child(child)
		child.queue_free()

# Function to handle champion button press
func _on_champion_button_pressed(champion):
	# Handle the selection logic here
	print("Selected: ", champion.champion_name)
	update_champion_details(champion)
	selected_champion = champion

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
	var lbl_skill= champion_details_container.get_node("lblSkill")
	var lbl_race= champion_details_container.get_node("lblRace")
	var lbl_level= champion_details_container.get_node("lblLevel")
	var lbl_experience= champion_details_container.get_node("lblExperience")
	var lbl_status= champion_details_container.get_node("lblStatus")
	
	lbl_name.text = "Name: " + champion.champion_name
	lbl_class.text = "Class: " + champion.champion_class
	lbl_spec.text = "Spec: " + champion.champion_specialization
	lbl_skill.text = "Skill level: " + str(champion.champion_skill) + " (" + skill_label + ")"
	lbl_race.text = "Race: " + champion.champion_race
	lbl_level.text = "Level: " + str(champion.champion_xp_level)
	lbl_experience.text = "XP: " + str(champion.champion_xp)
	lbl_status.text = "Status: " + champion.champion_status
	
	
# Function to update the roster list UI element
func update_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	
	GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = champion.create_champion_button(champion)
		#champion_roster_button.text = champion.champion_name
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
	

		roster_list.add_child(champion_roster_button)
		
		

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
		#champion_roster_button.text = champion.champion_name
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		
		
		roster_list.add_child(champion_roster_button)


func _on_start_crawl_button_pressed():
	if selected_champion:
		GameManager.set_selected_champion(selected_champion)
		print("Pressed start Survivor Mode with champion: ", selected_champion.champion_name)
		get_tree().change_scene_to_file("res://crawler_world.tscn")
	else:
		print("No champion selected!")
