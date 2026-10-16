extends Node2D


var dungeon_manager_instance

var background_node
var parallax_factor = 0.05  # Adjust this value to control the strength of the parallax effect
var spring_factor = 0.05  # Adjust this value to control the strength of the spring effect
var viewport_size

var chat_panel_scene = preload("res://ChatPanel.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	background_node = get_node("Node2D/Background")
	print(background_node)
	var global_background_manager = GlobalBackgroundManager.new()
	background_node.texture = global_background_manager.get_background("main")
	viewport_size = get_viewport_rect().size
	
	var background_texture_size = background_node.texture.get_size()
	var scale = viewport_size / background_texture_size
	#background_node.scale = scale * 1.2
	
	var dungeon_play_node = Node2D.new()
	dungeon_play_node.name = "DungeonPlayScene" # Optional: Set a name for debugging purposes


	get_tree().get_root().add_child(dungeon_play_node)
	print("Dungeon Play Node is initiated")
	

	#var global_background_manager = GlobalBackgroundManager.new()

		
  # Load the PackedScene
	var chat_panel = chat_panel_scene.instantiate()  # Create an instance of the scene
	add_child(chat_panel)  # Add the instance to the scene tree


# Called every frame. 'delta' is the elapsed time since the previous frame.
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


func _on_test_1a_pressed():
	print("Welcome")


func _on_guild_house_pressed():
	get_tree().change_scene_to_file("res://guild_house.tscn")


func _on_quit_game_pressed():
	get_tree().quit()

	


func _on_go_into_battle_pressed():
	get_tree().change_scene_to_file("res://dungeons_play_scene.tscn")
