extends Control

# Variables for dragging
var dragging = false
var drag_offset = Vector2.ZERO

# Reference to the item container and other UI elements
@onready var guild_inventory_container = $VBoxContainer/ScrollContainer/GuildInventoryContainer
@onready var item_description = $ItemDescription
@onready var use_item_button = $UseItemButton
@onready var target_select = $TargetSelect
@onready var generate_random_item_button = $GenerateRandomItemButton

# Reference to GlobalData
#@onready var global_data = get_node("/root/GlobalData")
#@onready var item_database = get_node("/root/ItemDatabase")
# Store the selected item
var selected_item = null
var selected_champion
# List to store all inventory items (optional)
var inventory_items = []

# Called when the node enters the scene tree
func _ready():
	use_item_button.connect("pressed", Callable(self, "_on_UseItemButton_pressed"))
	generate_random_item_button.connect("pressed", Callable(self, "_on_GenerateRandomItemButton_pressed"))
	update_guild_roster()
	# Populate the inventory container with items from the global inventory
	populate_inventory_from_global()

	
	#pass
# Function to update the guild roster in the target select dropdown
func update_guild_roster():
	target_select.clear()
	var guild_roster = GlobalData.get_guild_roster()
	for champion in guild_roster:
		target_select.add_item(champion.champion_name)

func _on_TitleBar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging = true
			drag_offset = event.global_position - position
		elif not event.pressed:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = event.global_position - drag_offset

# Function to add an item to the inventory
func add_item_to_inventory(item):
	GlobalData.add_item_to_global_inventory(item)  # Add to the global inventory list
	populate_inventory_from_global()  # Refresh the inventory display
# Function to populate the inventory container from the global inventory
func populate_inventory_from_global():
	# Remove all existing children
	print("Called populate inventory from global")
	for child in guild_inventory_container.get_children():
		guild_inventory_container.remove_child(child)
		child.queue_free()
	
	# Add items from the global inventory
	for item in GlobalData.global_inventory_items:
		var item_button = Button.new()
		item_button.text = item.item_name
		item_button.connect("pressed", Callable(self, "_on_item_button_pressed").bind(item))
		guild_inventory_container.add_child(item_button)

		

# Function to handle item button pressed
func _on_item_button_pressed(item):
	selected_item = item
	item_description.text = item.item_description



func _on_generate_random_item_button_pressed():
	var random_item = ItemDatabase.get_random_item()
	print("Pressed Generate Random Item")
	add_item_to_inventory(random_item)


# Function to handle use item button pressed
func _on_use_item_button_pressed():
	if selected_item != null:
		var selected_target_name = target_select.get_item_text(target_select.selected)
		var selected_target = GlobalData.get_champion_by_name(selected_target_name)
		if selected_item.item_category == "equipment":
	
			if selected_target != null:
				if selected_item.required_level <= selected_target.champion_xp_level:
					selected_item.use_item.call(selected_target, selected_item)
					item_description.text = "Used " + selected_item.item_name + " on " + selected_target_name + ". Please select another item."
					var panel = get_tree().get_first_node_in_group("champion_panel")
					if panel and panel.is_visible_in_tree() and panel.has_method("open"):
						panel.open(selected_target) # refresh with the champion
			# Debug print
					print("Attempting to remove item: " + selected_item.item_name)
	
				# Remove the item from the inventory container and global list
					GlobalData.remove_item_from_global_inventory(selected_item)
					populate_inventory_from_global()
					print("Equipped " + selected_item.item_name + " from inventory.")
				else:
					item_description.text = "Champion level too low to equip " + selected_item.item_name
				
				selected_item = null  # Clear the selected item
			else:
				item_description.text = "Target not found."
				
		else:
			selected_item.use_item.call(selected_target)
			item_description.text = "Used " + selected_item.item_name + " on " + selected_target_name + ". Please select another item."

			# Debug print
			print("Attempting to remove item: " + selected_item.item_name)

			# Remove the item from the inventory container and global list
			GlobalData.remove_item_from_global_inventory(selected_item)
			populate_inventory_from_global()
			print("Removed " + selected_item.item_name + " from inventory.")

			selected_item = null  # Clear the selected item
	else:
		item_description.text = "Target not found."
		print("Please select an item.")
			


# Function to handle close inventory panel button pressed
func _on_close_inventory_panel_button_pressed():
	hide()
	print("Inventory Panel closed")
