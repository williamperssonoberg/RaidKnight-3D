extends Node2D

# Load the GlobalBackgroundManager script
#var global_background_manager = preload("res://GlobalBackgroundManager.gd")
#var background_manager_instance = null

var background_node

var parallax_factor = 0.05  # Adjust this value to control the strength of the parallax effect
var spring_factor = 0.05  # Adjust this value to control the strength of the spring effect
var viewport_size

func _ready():
	background_node = get_node("Node2D/Background")
	print(background_node)
	var global_background_manager = GlobalBackgroundManager.new()
	background_node.texture = global_background_manager.get_background("start")
	viewport_size = get_viewport_rect().size
	
	var background_texture_size = background_node.texture.get_size()
	var scale = viewport_size / background_texture_size
	background_node.scale = scale * 1.2
	
	if get_tree().get_root().has_node("HUD"):
		get_tree().get_root().get_node("HUD").hide()	

	
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
	background_node.position.x = clamp(background_node.position.x, -viewport_size.x * 0.2, viewport_size.x * 0.2)
	background_node.position.y = clamp(background_node.position.y, -viewport_size.y * 0.2, viewport_size.y * 0.2)


func _on_start_pressed():
	print("Start Game button pressed")
	get_tree().change_scene_to_file("res://main_scene.tscn")
	
func _on_load_pressed():
	print("Load Game button pressed")
	get_tree().change_scene_to_file("res://main_scene.tscn")
	
func _on_quit_pressed():
	get_tree().quit() 
	print("Quit Game button pressed")
	
