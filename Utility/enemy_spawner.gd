extends Node2D

@export var spawns: Array[Spawn_info] = []
@export var enemy_types: Array[PackedScene] = []  # Enemy pool to choose from

#@onready var player = get_tree().get_first_node_in_group("PlayerContainer")

var time = 0
var player = null
var enemy_cap = 50  # Max enemies allowed at a time
var remove_count = 10  # How many enemies to remove if cap is exceeded
# Store difficulty and dungeon level
var dungeon_level = 1
var difficulty_multiplier = 1.0  # Affects enemy numbers & spawn speed

signal changetime(time)

var world: Node = null

func _ready():
	await get_tree().process_frame  # Wait one frame to ensure player exists
	player = get_tree().get_first_node_in_group("player")  # Group name should match what you set
	if not player:
		print("Error: No player found in group 'player'")	
		
	
	# Fetch dungeon parameters from GameManager
	if GameManager.dungeon_parameters:
		dungeon_level = GameManager.dungeon_parameters.get("monster_level", 1)
		difficulty_multiplier = get_difficulty_multiplier(GameManager.dungeon_parameters.get("difficulty", "normal"))
		
	print("📌 Dungeon Level:", dungeon_level, "| Difficulty Multiplier:", difficulty_multiplier)
		
	world = get_parent()  # crawler_world is the direct parent
	connect("changetime",Callable(player,"change_time"))

func _on_timer_timeout():
	time += 1

	# Get all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemies")

	# If too many enemies, remove the 10 farthest ones
	if enemies.size() > enemy_cap:
		remove_farthest_enemies(enemies)
		
	# Determine number of enemies to spawn based on time & difficulty
	var base_enemy_count = int(1 + (time * 0.1) * difficulty_multiplier)  # Increases over time
	var enemies_to_spawn = min(base_enemy_count, 10)  # Cap to prevent over-spawning

	print("👹 Spawning ", enemies_to_spawn, " enemies at Time: ", time)
	
	for _i in range(enemies_to_spawn):
		spawn_enemy()

	emit_signal("changetime", time)

func remove_farthest_enemies(enemies):
	# Sort enemies by distance from player (descending)
	enemies.sort_custom(func(a, b): return a.global_position.distance_to(player.global_position) > b.global_position.distance_to(player.global_position))

	# Remove the 10 farthest enemies
	for i in range(min(remove_count, enemies.size())):
		enemies[i].queue_free()
	
	print("💀 Removed ", min(remove_count, enemies.size()), " farthest enemies!")

func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(0.6,1)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up","down","right","left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)	
	var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
	return Vector2(x_spawn, y_spawn)

func get_difficulty_multiplier(difficulty):
	match difficulty:
		"normal":
			return 1.0
		"uncommon":
			return 1.2
		"rare":
			return 1.5
		"epic":
			return 2.0
		"legendary":
			return 3.0
	return 1.0  # Default to normal


func spawn_enemy():
	if enemy_types.is_empty():
		print("❌ No enemy types defined!")
		return
	
	var enemy_scene = enemy_types.pick_random()  # Pick a random enemy from the pool
	var enemy_instance = enemy_scene.instantiate()
	#enemy_instance.global_position = get_random_position()

	# Ask world for a valid room position
	if world and world.has_method("random_spawn_position"):
		enemy_instance.global_position = world.random_spawn_position()
	else:
		enemy_instance.global_position = player.global_position  # fallback
	
	# Scale enemy stats based on dungeon level
	enemy_instance.set_level(dungeon_level + randi_range(-2, 2))  

	# Hook the death -> world XP handler
	if enemy_instance.has_signal("enemy_defeated") and world:
		enemy_instance.connect("enemy_defeated", Callable(world, "_on_enemy_defeated"))

	add_child(enemy_instance)
