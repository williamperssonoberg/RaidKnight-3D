extends Node3D

@export var enemy_types: Array[PackedScene] = []

var time := 0
var player: Node3D = null
var world: Node3D = null

var enemy_cap := 50
var remove_count := 10

var dungeon_level := 1
var difficulty_multiplier := 1.0


func _ready():
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("party_leader")

	if not player:
		print("ERROR: No player found in group 'party_leader'")

	world = get_parent()

	if GameManager.dungeon_parameters:
		dungeon_level = GameManager.dungeon_parameters.get(
			"monster_level", 1
		)

		difficulty_multiplier = get_difficulty_multiplier(
			GameManager.dungeon_parameters.get(
				"difficulty", "normal"
			)
		)

	print(
		"Dungeon Level: ", dungeon_level,
		" | Difficulty Multiplier: ", difficulty_multiplier
	)


func _on_timer_timeout() -> void:
	time += 1

	var enemies = get_tree().get_nodes_in_group("enemies")

	if enemies.size() > enemy_cap:
		remove_farthest_enemies(enemies)

	var base_enemy_count = int(
		1 + (time * 0.1) * difficulty_multiplier
	)

	var enemies_to_spawn = min(base_enemy_count, 10)

	print(
		"Spawning ", enemies_to_spawn,
		" enemies at Time: ", time
	)

	for _i in range(enemies_to_spawn):
		spawn_enemy()

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

func remove_farthest_enemies(enemies):
	enemies.sort_custom(
		func(a, b):
			return a.global_position.distance_to(player.global_position) \
			> b.global_position.distance_to(player.global_position)
	)

	for i in range(min(remove_count, enemies.size())):
		enemies[i].queue_free()		
