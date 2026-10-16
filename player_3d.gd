extends CharacterBody3D

@onready var extra_player_scene = preload("res://player/extra_player_3D.tscn")


var leader = null  # Store the leader
var rotation_speed = 10.0  # Degrees per second (increase speed)
var last_mouse_pos = Vector2.ZERO

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
var spell_power = 0
var crit_rating = 0
var crit_damage = 0
var hp = 80
var maxhp = 80
var movement_speed = 100.0
var original_offsets = {}  # Stores the original relative positions of party members
var formation_move_speed = 200.0  # Adjust this value to control movement speed
var dash_distance = 10  # Distance to move when dodging
var dash_cooldown = 1.0  # Time in seconds before dodging again
var can_dash = true  # Prevent spamming

var stat_term = 0
var skill_mult = 0
var trait_mult = 0
var spec_mult = 0

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

# Attack scenes
var attack_scene = null

var last_movement = Vector2.UP
var time = 0
var experience = 0
var experience_level = 1
var collected_experience = 0

#Preload Attacks
var iceSpear = preload("res://player/Attack/ice_spear_3D.tscn")






var current_anim: String = ""
var is_attacking: bool = false

@export var move_speed := 6.0

func _ready():
	# Load the selected champion from GameManager
	var champion_data = GameManager.selected_champion

func _physics_process(_delta):
	var input_dir := Input.get_vector(
		"left",
		"right",
		"up",
		"down"
	)

	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.y * move_speed

	move_and_slide()
	rotate_toward_mouse()
#	var mouse_pos = get_viewport().get_global_mouse_position()  # Get mouse position in world space
#	var direction_to_mouse = (mouse_pos - global_position).normalized()  # Get unit direction
#	var target_angle = rad_to_deg(direction_to_mouse.angle())  # Convert to degrees

#	rotate_formation(target_angle)  # Rotate formation based on mouse position
#	movement()


var start_room_position = Vector2.ZERO

func set_starting_position(start_room_from_setup):
	start_room_position = start_room_from_setup
	global_position = start_room_position
	print("✅ Player set at:", global_position)

func rotate_formation(angle):
	var leader_pos = global_position  # Store the leader's position
	#var new_angle = deg_to_rad(angle)  # Convert mouse angle to radians
	
	for child in get_children():
		if child is CharacterBody3D and child.scene_file_path == extra_player_scene.resource_path:

			if not original_offsets.has(child):
				original_offsets[child] = child.global_position - leader_pos  # Store new champion offset
			
			# Convert position relative to leader
			var offset = original_offsets[child]  # Get stored formation offset	
				
			var distance = offset.length()
			#var offset_angle = offset.angle()

			# Apply rotation

			#var rotated_angle = new_angle + offset_angle + deg_to_rad(90)  # Fix 90-degree offset



			#Smooth slow movement
			# Calculate target position 
			#var target_position = leader_pos + Vector3(
			#	cos(rotated_angle) * distance,
			#	sin(rotated_angle) * distance
			#)

			# ✅ NO tween / NO teleport.
			# Tell the follower where it should try to go.
			#if child.has_method("set_follow_target_position"):
			#	child.set_follow_target_position(target_position)
							
			# ✅ Check if a tween already exists and stop it before starting a new one
#			if child.has_meta("active_tween"):
#				var active_tween = child.get_meta("active_tween")
#				if active_tween.is_valid() and active_tween.is_running():
#					active_tween.stop()  # Stop the previous tween

			# ✅ Use ephemeral Tween (Godot 4) with calculated duration
#			var move_distance = child.global_position.distance_to(target_position)
#			var move_duration = move_distance / formation_move_speed  # Time = Distance / Speed
#			var tween = create_tween()
#			tween.tween_property(child, "global_position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			# Store the tween reference
#			child.set_meta("active_tween", tween)

func _input(event):
	if event.is_action_pressed("Dash") and can_dash:
		perform_dash()

func perform_dash():
	if not can_dash:
		return

	# Disable dash temporarily
	can_dash = false
	
	# Get the mouse direction
	#var mouse_pos = get_viewport().get_global_mouse_position()
	var dash_direction := global_transform.basis.z
	#(mouse_pos - global_position).normalized()
	dash_direction.y = 0.0
	dash_direction = dash_direction.normalized()
	# Calculate the target position
	var dash_target = global_position + dash_direction * dash_distance

	# ✅ Use a tween to smoothly move the player
	var tween := create_tween()
	tween.tween_property(
		self,
		"global_position",
		dash_target,
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# ✅ Enable dodge again after cooldown
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
#	if mov.x > 0:
#		sprite.scale.x = -1  # Flip left ist för flip_h = true
#	elif mov.x < 0:
#		sprite.scale.x = 1   # Flip right ist för flip_h = false
	
		
	if mov != Vector2.ZERO:
		last_movement = mov



		
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
	if is_attacking:
		return  # don't override attack with walk/idle
#	if velocity.length() > 5:
#		play_anim("walk")
#	else:
#		play_anim("Idle") 

var viewport_size
var center
var mouse

var mouse_dir
var mouse_angle

func rotate_toward_mouse():
	viewport_size = get_viewport().get_visible_rect().size
	center = viewport_size * 0.5
	mouse = get_viewport().get_mouse_position()
	
	mouse_dir = mouse - center
	
	if mouse_dir.length() < 5.0:
		return

	mouse_dir = mouse_dir.normalized()

	mouse_angle = atan2(mouse_dir.x, mouse_dir.y)

	rotation.y = mouse_angle



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

	#_on_champion_stats_changed()
			
	skillful_skill = champion_data.skillful_skill
	
	#self.champion = champion
	#champion.champion_stats_changed.connect(_on_champion_stats_changed)
	#_on_champion_stats_changed()

	# Print debug info
	print("Survivor Player Loaded: ", champion.champion_class, champion.champion_specialization, champion.champion_race)
	print("Stats - STR:", strength, "AGI:", agility, "INT:", intellect, "STAM:", stamina)
	attack()

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

#Enemy Related
var enemy_close = []

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else: 
		return null

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")


#IceSpear
var icespear_ammo = 1
var icespear_baseammo = 1
var icespear_attackspeed = 1.5
var icespear_level = 1


func attack():
	print("starting champion Ice Spear attacks")
	iceSpearTimer.wait_time = icespear_attackspeed * (1 - spell_cooldown)
	if iceSpearTimer.is_stopped():
		iceSpearTimer.start()	



func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()
	#play_attack_animation()	


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo <= 0:
		return

	var target_position = get_random_target()

	if target_position == null:
		icespear_ammo = 0
		return

	var icespear_attack = iceSpear.instantiate()

	get_parent().add_child(icespear_attack)

	icespear_attack.setup(
		self,
		global_position,
		target_position
	)

	icespear_ammo -= 1

	if icespear_ammo > 0:
		iceSpearAttackTimer.start()
	else:
		iceSpearAttackTimer.stop()


func _on_enemy_detection_area_3d_body_entered(body: Node3D):
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_3d_body_exited(body: Node3D):
	if enemy_close.has(body):
		enemy_close.erase(body)

func take_damage(damage):
	hp -= damage
	print(champion_name, " took ", damage, " damage. HP: ", hp)
	if hp <= 0:
		death()
		
func death():
	#deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	#var tween = deathPanel.create_tween()
	#tween.tween_property(deathPanel,"position",Vector2(850,200),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	#tween.play()
	#if time >= 300:
	#	lblResult.text = "You Win"
	#	sndVictory.play()
	#else:
	#	lblResult.text = "You Died"	
	#	sndLose.play()
