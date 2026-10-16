extends CanvasLayer
# Ensure GlobalData is loaded
#const GlobalData = preload("res://GlobalData.gd")
var change_name_dialog
var guild_roster = [] # List to store champions in the guild roster
var champion_details_container
var roster_list # Reference to UI element displaying the guild roster
var selected_champion # Declare a variable to store the currently selected champion
#var global_data_node

	
func _ready():
	print("Guild Roster scene ready!")
	champion_details_container = get_node("Control/ChampionDetailsContainer")
	roster_list = get_node("Control/GuildRosterContainer")
	#global_data_node = get_node("/root/GlobalData")
	change_name_dialog = get_node("Control/ChangeNameWindow")

	
	show_global_roster_list()
	# Create an instance of the GlobalData class
	#var global_data_instance = GlobalData.new()
	# Retrieve guild roster data from the global script
	#var guild_roster_data = global_data_instance.get_guild_roster()
	# Use guild_roster_data to populate the UI with champion details

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_go_to_recruitment_pressed():
	get_tree().change_scene_to_file("res://recruitment.tscn")
	
func _on_go_to_guild_house_pressed():
	get_tree().change_scene_to_file("res://guild_house.tscn")
	
	
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
	var lbl_race = champion_details_container.get_node("lblRace")
	var lbl_level = champion_details_container.get_node("lblLevel")
	var lbl_status = champion_details_container.get_node("lblStatus")

	lbl_name.text = "Name: " + champion.champion_name
	lbl_class.text = "Class: " + champion.champion_class
	lbl_spec.text = "Spec: " + champion.champion_specialization
	lbl_skill.text = "Skill level: " + str(champion.champion_skill) + " (" + skill_label + ")"
	lbl_race.text = "Race: " + champion.champion_race
	lbl_level.text = "Level: " + str(champion.champion_xp_level)
	lbl_status.text = "Status: " + champion.champion_status

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

# Function to update the roster list UI element
func update_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	
	GlobalData.set_guild_roster(guild_roster)
	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = Button.new()
		champion_roster_button.text = champion.champion_name
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		
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


func show_global_roster_list():
	 # Clear the list content
	clear_container_children(roster_list)
	print("Show global roster list function called")

	# Retrieve guild roster data from the global script
	guild_roster = GlobalData.get_guild_roster()
	
	print(guild_roster)	

	
	# Add champions in the guild roster to the roster list
	for champion in guild_roster:
		var champion_roster_button = Button.new()
		champion_roster_button.text = champion.champion_name
		champion_roster_button.connect("pressed", func(): _on_champion_button_pressed(champion))
		
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

#----------------------------------------------CHANGE SPECIALIZATION




#-------------------- -------------------------CHANGE NAME ON CHAMPION 

func _on_change_champion_name_pressed():
	change_name_dialog.visible = true
	
func _on_window_close_requested():
	change_name_dialog.visible = false

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
