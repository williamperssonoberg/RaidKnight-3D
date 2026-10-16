extends Button

# Load the Champion Panel scene
var ChampionPanelScene = preload("res://champion_panel.tscn")
# Store a reference to the champion panel instance
var champion_panel_instance = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

# Function to handle button pressed
func open_champion_panel(champion: Champion):
	
	# Check if the champion panel instance exists
	if champion_panel_instance and champion_panel_instance.is_inside_tree():
		# Toggle visibility
		if champion_panel_instance.is_visible():
			champion_panel_instance.hide()
			print("Closed Champion Panel")
		else:
			champion_panel_instance.show()
			champion_panel_instance.open(champion)  # Populate panel here
			print("Opened Champion Panel")
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
		champion_panel_instance.open(champion)  # Populate panel here
		print("Opened Champion Panel for: ", champion)

# Function to handle notifications
func _notification(what):
	print("Notification received: ", what)
	if what == NOTIFICATION_EXIT_TREE:
		if champion_panel_instance:
			champion_panel_instance.queue_free()
			champion_panel_instance = null
			print("Closed Champion Panel on scene change")


#var champion_panel_scene = preload("res://champion_panel.tscn")
#var champion_panel: Control = null

#func _ready():
	# Create panel on startup but keep hidden
#	champion_panel = champion_panel_scene.instantiate()
#	champion_panel.visible = false
#	add_child(champion_panel)
#	print("ChampionManager.gd initiated.")

#func open_champion_panel(champion: Champion):
#	if not is_instance_valid(champion_panel):
#		champion_panel = champion_panel_scene.instantiate()
#		add_child(champion_panel)  # Ensure it's added to the scene tree
#	champion_panel.open(champion)

#func close_champion_panel():
#	if is_instance_valid(champion_panel):
#		champion_panel.visible = false


func _on_pressed() -> void:
	pass # Replace with function body.
