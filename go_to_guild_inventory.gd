extends Button


# Load the InventoryPanel scene
var InventoryPanelScene = preload("res://inventory_panel.tscn")
# Store a reference to the inventory panel instance
var inventory_panel_instance = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

# Function to handle button pressed
func _on_pressed():
	# Check if the inventory panel instance exists
	if inventory_panel_instance and inventory_panel_instance.is_inside_tree():
		# Toggle visibility
		if inventory_panel_instance.is_visible():
			inventory_panel_instance.hide()
			print("Closed Inventory Panel")
		else:
			inventory_panel_instance.show()
			print("Opened Inventory Panel")
	else:
		# Create an instance of the InventoryPanel scene
		inventory_panel_instance = InventoryPanelScene.instantiate()
		# Find or create the CanvasLayer for InventoryPanel
		var inventory_layer = get_tree().root.get_node("InventoryLayer")
		if not inventory_layer:
			inventory_layer = CanvasLayer.new()
			inventory_layer.name = "InventoryLayer"
			inventory_layer.layer = 2  # Ensure it's higher than other layers
			get_tree().root.add_child(inventory_layer)
			print("Created Layer with value " + str(inventory_layer.layer))
		
		# Add the instance to the inventory layer
		inventory_layer.add_child(inventory_panel_instance)
		
		# Optional: Adjust the inventory panel's position if needed
		inventory_panel_instance.position = Vector2(100, 100)  # Example position adjustment
		print("Opened Inventory Panel: " + str(inventory_panel_instance))

# Function to handle notifications
func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		if inventory_panel_instance:
			inventory_panel_instance.queue_free()
			inventory_panel_instance = null
			print("Closed Inventory Panel on scene change")
