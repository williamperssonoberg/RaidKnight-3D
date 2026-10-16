extends Button

var selected_champion = null
# Load the Champion Panel scene
var ChampionPanelScene = preload("res://champion_panel.tscn")
# Store a reference to the champion panel instance
var champion_panel_instance = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func set_selected_champion(champion):
	selected_champion = champion
# Function to handle button pressed
func _on_pressed():
	
	# Access the root node of the current scene
	var root = get_tree().current_scene  # This gets the root node of the active scene
	print("Got root: ", root)
	# Check if the root node has the selected_champion variable. And the root node script needs a get_selected_champion function.
	if root.has_method("get_selected_champion"):
		var selected_champion = root.get_selected_champion()
		if selected_champion:
			print("Selected Champion: ", selected_champion.champion_name)
				# Check if the champion panel instance exists
			if champion_panel_instance and champion_panel_instance.is_inside_tree():
		# Toggle visibility - removed because I dont want the "inspect" button to close the inspect window.
			#	if champion_panel_instance.is_visible():
			#		champion_panel_instance.hide()
			#		print("Closed Champion Panel")
			#	else:
			#		champion_panel_instance.show()
				champion_panel_instance.open(selected_champion)  # Populate panel here
				print("Champion Panel opened with champion data of: ", selected_champion)
			else:
		# Create an instance of the championPanel scene
				champion_panel_instance = ChampionPanelScene.instantiate()
		# Find or create the CanvasLayer for championPanel
				var champion_panel_layer = get_tree().root.get_node("ChampionPanelLayer")
				if not champion_panel_layer:
					champion_panel_layer = CanvasLayer.new()
					champion_panel_layer.name = "ChampionPanelLayer"
					champion_panel_layer.layer = 2  # Ensure it's higher than other layers
					get_tree().root.add_child(champion_panel_layer)
					print("Created Layer with value " + str(champion_panel_layer.layer))
		
			# Add the instance to the champion layer
				champion_panel_layer.add_child(champion_panel_instance)
				champion_panel_instance.position = Vector2(700, 400)
				champion_panel_instance.open(selected_champion)  # Populate panel here
				print("Opened Champion Panel for: ", selected_champion)
			
			
		else:
			print("No champion selected!")
	else:
		print("The current scene doesn't support champion selection!")	
	


# Function to handle notifications
func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		if champion_panel_instance:
			champion_panel_instance.queue_free()
			champion_panel_instance = null
			print("Closed Champion Panel on scene change")
