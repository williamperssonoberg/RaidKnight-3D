# GlobalBackgroundManager.gd

extends Node2D

class_name GlobalBackgroundManager

func _ready():
	pass
# Define a singleton instance
var instance = null



# Define background textures for each scene
var backgrounds = {
	"solo_play_scene": preload("res://backgrounds/885928.jpg"),
	"start": preload("res://backgrounds/start_screen_bg.jpg"),
	"main": preload("res://backgrounds/main_city_bg.jpg"),
	"recruitment": preload("res://backgrounds/recruitment_bg.jpg")
	# Add more scenes and backgrounds as needed
}

# Function to get the background texture for a scene
func get_background(scene_name: String) -> Texture:
	if scene_name in backgrounds:
		return backgrounds[scene_name]
	else:
		print("Background for scene", scene_name, "not found.")
		return null

# Function to get the singleton instance
func get_instance():
	if instance == null:
		instance = GlobalBackgroundManager.new()
		instance.name = "GlobalBackgroundManager"  # Optional: Set a name for debugging
	return instance

# Function to set the background for a specific scene
func set_background_for_scene(scene_name: String, background_node_path: NodePath):
	print("Setting background for scene:", scene_name)
	if scene_name in backgrounds:
		var background_texture = backgrounds[scene_name]
		# Use get_tree().current_scene to access the currently active scene
		var scene_root = get_tree().current_scene
		if scene_root:
			# Use the find_node function to search for the node by its path
			var background_node = scene_root.find_node(background_node_path)
			if background_node and background_node is Sprite2D:
				background_node.texture = background_texture
				print("Background set successfully.")
			else:
				print("Background node not found or not of type Sprite2D.")
		else:
			print("No active scene found.")
	else:
		print("Background for scene", scene_name, "not found.")
