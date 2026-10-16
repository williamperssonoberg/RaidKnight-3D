extends CharacterBody3D

@export var follow_speed: float = 500.0
@export var stop_distance: float = 10.0
@export var follow_target: Node3D
@export var follow_offset: Vector3 = Vector3.ZERO

var follow_target_position: Vector3

var champion
var champion_class = ""
var champion_spec = ""
var champion_race = ""
var item_level = 1
var skillful_skill
#var character_scene = preload("res://character.tscn")  # Load the character scene
var character_instance  # Store the character instance
var champion_data
var champion_name

var strength = 0
var agility = 0
var intellect = 0
var stamina = 0
var attack_power = 0
var hp = 80
var maxhp = 80
var movement_speed = 100.0
var _last_pos: Vector3
var stat_term = 0
var skill_mult = 0
var trait_mult = 0
var spec_mult = 0

# Attack scenes
var attack_scene = null

var last_movement = Vector2.UP
var time = 0
var experience = 0
var experience_level = 1
var collected_experience = 0

func _ready():
	# Load the selected champion from GameManager
	champion_data = GameManager.selected_champion
#	setup_from_champion(champion_data)	
#	if champion_data:
#		spawn_champion(champion_data)
#	else:
#		print("No champion data found in GameManager!")	
#	upgrade_character("icespear1")
#	attack()
#	set_expbar(experience, calculate_experiencecap())
	follow_target_position = global_position
	_last_pos = global_position	
	#_on_hurt_box_hurt(0,0,0)


func set_follow_target_position(pos: Vector3) -> void:
	follow_target_position = pos

func setup_from_champion(champion_data):
	# Store basic champion info
	print("Champion Object Received in Player:", champion_data)	
	champion = champion_data

	# Remove existing character instance if it exists
	if character_instance:
		character_instance.queue_free()

	# Spawn character.tscn inside player.tscn
	#character_instance = character_scene.instantiate()
	#$CharacterContainer/CharacterHolder.add_child(character_instance)  # Attach to CharacterHolder node		

	# Pass champion data to character instance
	#character_instance.set_champion_data(champion_data)

	# Wait for the node to fully appear
	await get_tree().process_frame

	# Assign sprite AFTER character_instance is created
	#sprite = character_instance #.get_node("Skeleton2D/Body")  # Adjust path to the actual sprite
	#print("Sprite assigned:", sprite)

	# Debugging
	print("Character scene instantiated for: ", champion_data.champion_name)

	# Assign stats based on item level
	strength = champion_data.champion_item_level
	agility = champion_data.champion_item_level
	intellect = champion_data.champion_item_level
	stamina = champion_data.champion_item_level
	champion_spec = champion_data.champion_specialization
	champion_class = champion_data.champion_class
	champion_race = champion_data.champion_race
	champion_name = champion_data.champion_name
	# Calculate HP
	maxhp = stamina * 10
	hp = maxhp
	skillful_skill = champion_data.skillful_skill	
	print("Survivor Player Loaded: ", champion.champion_class, champion.champion_specialization, champion.champion_race)
	print("Stats - STR:", strength, "AGI:", agility, "INT:", intellect, "STAM:", stamina)
	#attack()


func calculate_experience(gem_exp):
#	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp



func perform_attack():
	if attack_scene:
		var attack_instance = attack_scene.instantiate()
		get_parent().add_child(attack_instance)
		attack_instance.global_position = global_position  # Set attack origin

	else:
		print("No attack assigned for ", champion_class, " - ", champion_spec)


func take_damage(damage):
	hp -= damage
	
	print(champion_name, " took ", damage, " damage. HP: ", hp)

	if hp <= 0:
		death()
		
func death():
	#deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true		
