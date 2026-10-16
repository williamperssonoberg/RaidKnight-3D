extends CharacterBody2D


var leader = null  # Store the leader
var rotation_speed = 10.0  # Degrees per second (increase speed)
var last_mouse_pos = Vector2.ZERO

var champion
var champion_class = ""
var champion_spec = ""
var champion_race = ""
var item_level = 1
var skillful_skill
var character_scene = preload("res://character.tscn")  # Load the character scene
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

#Preload Attacks
var iceSpear = preload("res://player/Attack/ice_spear.tscn")
var tornado = preload("res://player/Attack/tornado.tscn")
var javelin = preload("res://player/Attack/javelin.tscn")
var fire_blast = preload("res://player/Attack/fire_blast.tscn")
var shadow_strike = preload("res://player/Attack/shadow_strike.tscn")
var holy_smite = preload("res://player/Attack/holy_smite.tscn")
var lightning_bolt = preload("res://player/Attack/lightning_bolt.tscn")
var berserker_slash = preload("res://player/Attack/berserker_slash.tscn")
var shield_bash = preload("res://player/Attack/shield_bash.tscn")
var shadow_bolt = preload("res://player/Attack/shadow_bolt.tscn")

var current_anim: String = ""
var is_attacking: bool = false

func play_anim(name: String) -> void:
	if current_anim == name:
		return  # already playing
	current_anim = name
	if character_instance and character_instance.has_method("play_animation"):	
		character_instance.play_animation(name)  # forwards to Character.tscn


func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "basic_attack_1":
		is_attacking = false
		current_anim = ""  # allow replay	
		#print("Attack animation finished!")
		# go back to an appropriate movement anim next frame

func play_attack_animation():
	if is_attacking:
		#print("Didn't attack because it was already playing")
		return  # don't restart it constantly
	is_attacking = true
	play_anim("basic_attack_1")
		# wait for the animation to finish once, then unlock
	var anim_player: AnimationPlayer = character_instance.get_node("AnimationPlayer")
	if anim_player:
		anim_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	#print("Executed attack animation func.")

func setup_from_champion(champion_data):
	# Store basic champion info
	print("Champion Object Received in Player:", champion_data)	
	champion = champion_data

	# Remove existing character instance if it exists
	if character_instance:
		character_instance.queue_free()

	# Spawn character.tscn inside player.tscn
	character_instance = character_scene.instantiate()
	$CharacterContainer/CharacterHolder.add_child(character_instance)  # Attach to CharacterHolder node		

	# Pass champion data to character instance
	character_instance.set_champion_data(champion_data)

	# Wait for the node to fully appear
	await get_tree().process_frame

	# Assign sprite AFTER character_instance is created
	sprite = character_instance #.get_node("Skeleton2D/Body")  # Adjust path to the actual sprite
	print("Sprite assigned:", sprite)

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
	champion.champion_stats_changed.connect(_on_champion_stats_changed)
	_on_champion_stats_changed()

	# Print debug info
	print("Survivor Player Loaded: ", champion.champion_class, champion.champion_specialization, champion.champion_race)
	print("Stats - STR:", strength, "AGI:", agility, "INT:", intellect, "STAM:", stamina)
	attack()


func _on_champion_stats_changed():
	# pull updated stats into the runtime actor
	#movement_speed = champion.movement_speed
	maxhp = champion.champion_maxhp
	hp = min(hp, maxhp)
	print("_on_champion_stats_changed called for leader: ", champion.champion_name, " with new ilvl ", champion.champion_item_level)
	#var champion = character_instance
	
	match champion.champion_specialization:
		"Stalker":  # Rogue
			stat_term = champion.champion_agility * 0.6
			#skill_mult = 0.5 + (skill_level / 100.0) * 0.5   # maps 0..100 → 0.5..1.0
			trait_mult = champion.get_skillful_multiplier()
			attack_power = stat_term * trait_mult
			attack_scene = shadow_strike
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shadow Strike on ", champion_name, " is ", attack_power)
		"Divine":  # Priest
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 1.5
			attack_power = stat_term * trait_mult
			attack_scene = holy_smite
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Holy Smite on ", champion_name, " is ", attack_power)
		"Voodoo":  # Priest (Shadow)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 1.8
			attack_power = stat_term * trait_mult
			attack_scene = shadow_bolt
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shadow Bolt on ", champion_name, " is ", attack_power)
		"Soldier":  # Fighter (Balanced)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_strength * 2
			attack_power = stat_term * trait_mult
			attack_scene = shield_bash
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shield Bash on", champion_name, " is ", attack_power)
		"Berserker":  # Fighter (Aggressive)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_strength * 2.5
			attack_power = stat_term * trait_mult
			attack_scene = berserker_slash
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Berserker Slash on ", champion_name, " is ", attack_power)
		"Defender":  # Crusader (Tank)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_strength * 1.5
			attack_power = stat_term * trait_mult
			attack_scene = shield_bash
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shield Bash ", champion_name, " is ", attack_power)
		"Lightbringer":  # Crusader (Support)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 1.5
			attack_power = stat_term * trait_mult
			attack_scene = holy_smite
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Holy Smite on ", champion_name, " is ", attack_power)
		"Water":  # Shaman (Healing)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 1.5
			attack_power = stat_term * trait_mult
			attack_scene = holy_smite
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Holy Smite on ", champion_name, " is ", attack_power)
		"Earth":  # Shaman (Tank)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_strength * 1.8
			attack_power = stat_term * trait_mult
			attack_scene = shield_bash
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shield Bash on ", champion_name, " is ", attack_power)
		"Wind":  # Shaman (Ranged)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_agility * 2
			attack_power = stat_term * trait_mult
			attack_scene = tornado
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Tornado on ", champion_name, " is ", attack_power)
		"Fire":  # Shaman (Spell DPS)
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 2
			attack_power = stat_term * trait_mult
			attack_scene = fire_blast
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Fire Blast on ", champion_name, " is ", attack_power)
		"Necromancer":  # Wizard
			trait_mult = champion.get_skillful_multiplier()
			stat_term = champion.champion_intellect * 2.2
			attack_power = stat_term * trait_mult
			attack_scene = shadow_bolt
			print("Gear updated! Based on stat_term = ", stat_term, " and multiplier the new attack_power for Shadow Bolt on ", champion_name, " is ", attack_power)
	# (and update attack scaling variables if you cache them)



func perform_attack():
	if attack_scene:
		var attack_instance = attack_scene.instantiate()
		get_parent().add_child(attack_instance)
		attack_instance.global_position = global_position  # Set attack origin

	else:
		print("No attack assigned for ", champion_class, " - ", champion_spec)

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var fireBlastAttackTimer = get_node("%FireBlastAttackTimer")
@onready var fireBlastTimer = get_node("%FireBlastTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelinBase = get_node("%JavelinBase")
@onready var shadowStrikeAttackTimer = get_node("%ShadowStrikeAttackTimer")
@onready var shadowStrikeTimer = get_node("%ShadowStrikeTimer")
@onready var shadowBoltTimer = get_node("%ShadowBoltTimer")
@onready var shadowBoltAttackTimer = get_node("%ShadowBoltAttackTimer")
@onready var holySmiteTimer = get_node("%HolySmiteTimer")
@onready var holySmiteAttackTimer = get_node("%HolySmiteAttackTimer")
@onready var berserkerSlashTimer = get_node ("%BerserkerSlashTimer")
@onready var berserkerSlashAttackTimer = get_node("%BerserkerSlashAttackTimer")
@onready var shieldBashTimer = get_node("%ShieldBashTimer")
@onready var shieldBashAttackTimer = get_node("%ShieldBashAttackTimer")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0


#IceSpear
var icespear_ammo = 1
var icespear_baseammo = 1
var icespear_attackspeed = 1.5
var icespear_level = 1

#FireBlast
var fireblast_ammo = 1
var fireblast_baseammo = 1
var fireblast_attackspeed = 1.5

#ShadowStrike
var shadowstrike_ammo = 1
var shadowstrike_baseammo = 1
var shadowstrike_attackspeed = 1.5

#ShadowBolt
var shadowbolt_ammo = 1
var shadowbolt_baseammo = 1
var shadowbolt_attackspeed = 1.5


#HolySmite
var holysmite_ammo = 1
var holysmite_baseammo = 1
var holysmite_attackspeed = 1.5

#BerserkerSlash
var berserker_slash_ammo = 1
var berserker_slash_baseammo = 1
var berserker_slash_attackspeed = 1.5

#ShieldBash
var shieldbash_ammo = 1
var shieldbash_baseammo = 1
var shieldbash_attackspeed = 1.5

#Tornado
var tornado_ammo = 1
var tornado_baseammo = 1
var tornado_attackspeed = 3
var tornado_level = 1

#Javelin
var javelin_ammo = 0
var javelin_level = 0


#Enemy Related
var enemy_close = []

var sprite = Sprite2D

@onready var character_container = $CharacterContainer

#@onready var sprite = $CharacterHolder
@onready var walkTimer = get_node("%walkTimer")

#GUI
#@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_Level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://player/GUI/item_container.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")


#Signal
signal playerdeath

@onready var extra_player_scene = preload("res://player/extra_player.tscn")  # Adjust path if needed
# New variable to store the starting room position
var start_room_position = Vector2.ZERO

func _ready():
	# Load the selected champion from GameManager
	var champion_data = GameManager.selected_champion
#	setup_from_champion(champion_data)	
#	if champion_data:
#		spawn_champion(champion_data)
#	else:
#		print("No champion data found in GameManager!")	
#	upgrade_character("icespear1")
#	attack()
#	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)
	# Move the player to the start room position

	
	
	

func _physics_process(delta):
	var mouse_pos = get_global_mouse_position()  # Get mouse position in world space
	var direction_to_mouse = (mouse_pos - global_position).normalized()  # Get unit direction
	var target_angle = rad_to_deg(direction_to_mouse.angle())  # Convert to degrees

	rotate_formation(target_angle)  # Rotate formation based on mouse position
	movement()

func set_starting_position(start_room_from_setup):
	start_room_position = start_room_from_setup
	global_position = start_room_position
	print("✅ Player set at:", global_position)
	
	# Move Camera2D to the same position
	$Camera2D.global_position = global_position
	print("✅ Camera moved to:", $Camera2D.global_position)	
	
func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if mov.x > 0:
		sprite.scale.x = -1  # Flip left ist för flip_h = true
	elif mov.x < 0:
		sprite.scale.x = 1   # Flip right ist för flip_h = false
	
		
	if mov != Vector2.ZERO:
		last_movement = mov



		
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
	if is_attacking:
		return  # don't override attack with walk/idle
	if velocity.length() > 5:
		play_anim("walk")
	else:
		play_anim("Idle") 
	


func _process(delta):
	pass
	

var original_offsets = {}  # Stores the original relative positions of party members
var formation_move_speed = 200.0  # Adjust this value to control movement speed

func rotate_formation(angle):
	var leader_pos = global_position  # Store the leader's position
	var new_angle = deg_to_rad(angle)  # Convert mouse angle to radians
	
	for child in get_children():
		if child is Node2D and child.scene_file_path == extra_player_scene.resource_path:

			if not original_offsets.has(child):
				original_offsets[child] = child.global_position - leader_pos  # Store new champion offset
			
			# Convert position relative to leader
			var offset = original_offsets[child]  # Get stored formation offset	
				
			var distance = offset.length()
			var offset_angle = offset.angle()

			# Apply rotation

			var rotated_angle = new_angle + offset_angle + deg_to_rad(90)  # Fix 90-degree offset



			#Smooth slow movement
			# Calculate target position 
			var target_position = leader_pos + Vector2(
				cos(rotated_angle) * distance,
				sin(rotated_angle) * distance
			)

			# ✅ NO tween / NO teleport.
			# Tell the follower where it should try to go.
			if child.has_method("set_follow_target_position"):
				child.set_follow_target_position(target_position)
							
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

var dash_distance = 100  # Distance to move when dodging
var dash_cooldown = 1.0  # Time in seconds before dodging again
var can_dash = true  # Prevent spamming

func _input(event):
	if event.is_action_pressed("Dash") and can_dash:
		perform_dash()

func perform_dash():
	if not can_dash:
		return

	# Disable dash temporarily
	can_dash = false
	
	# Get the mouse direction
	var mouse_pos = get_global_mouse_position()
	var dash_direction = (mouse_pos - global_position).normalized()

	# Calculate the target position
	var dash_target = global_position + (dash_direction * dash_distance)

	# ✅ Use a tween to smoothly move the player
	var tween = create_tween()
	tween.tween_property(self, "global_position", dash_target, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# ✅ Enable dodge again after cooldown
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true



func attack():
	if champion_spec == "Wind":  # Shaman - Wind
		print("starting Wind Shaman attacks")
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown)
		iceSpearTimer.wait_time = icespear_attackspeed * (1 - spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()

		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()	

	elif champion_spec == "Fire":  # Shaman - Fire
		print("starting Fire Shaman attacks")
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown)		
		fireBlastTimer.wait_time = fireblast_attackspeed * (1 - spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()

		if fireBlastTimer.is_stopped():
			fireBlastTimer.start()

	elif champion_spec == "Stalker":  # Rogue
		print("starting Stalker attacks")
		shadowStrikeTimer.wait_time = shadowstrike_attackspeed * (1 - spell_cooldown)
		if shadowStrikeTimer.is_stopped():
			shadowStrikeTimer.start()

		shadowBoltTimer.wait_time = shadowbolt_attackspeed * (1 - spell_cooldown)
		if shadowBoltTimer.is_stopped():
			shadowBoltTimer.start()
	elif champion_spec == "Divine":  # Priest - Divine
		print("starting Divine Priest attacks")
		fireBlastTimer.wait_time = fireblast_attackspeed * (1 - spell_cooldown)		
		if fireBlastTimer.is_stopped():
			fireBlastTimer.start()		
		holySmiteTimer.wait_time = holysmite_attackspeed * (1 - spell_cooldown)
		if holySmiteTimer.is_stopped():
			holySmiteTimer.start()
	elif champion_spec == "Voodoo":  # Priest - Voodoo (Shadow)
		print("starting Voodoo Priest attacks")
		shadowBoltTimer.wait_time = shadowbolt_attackspeed * (1 - spell_cooldown)
		if shadowBoltTimer.is_stopped():
			shadowBoltTimer.start()
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown)					
		if tornadoTimer.is_stopped():
			tornadoTimer.start()			
	elif champion_spec == "Soldier":  # Fighter - Soldier
		print("starting Fighter Soldier attacks")
		berserkerSlashTimer.wait_time = berserker_slash_attackspeed * (1 - spell_cooldown)
		if berserkerSlashTimer.is_stopped():
			berserkerSlashTimer.start()
		shieldBashTimer.wait_time = shieldbash_attackspeed * (1 - spell_cooldown)
		if shieldBashTimer.is_stopped():
			shieldBashTimer.start()			
	elif champion_spec == "Berserker":  # Fighter - Berserker
		print("starting Berserker attacks")
		berserkerSlashTimer.wait_time = berserker_slash_attackspeed * (1 - spell_cooldown)
		if berserkerSlashTimer.is_stopped():
			berserkerSlashTimer.start()
		shadowStrikeTimer.wait_time = shadowstrike_attackspeed * (1 - spell_cooldown)
		if shadowStrikeTimer.is_stopped():
			shadowStrikeTimer.start()			
	elif champion_spec == "Defender":  # Crusader - Defender (Tank)
		print("starting Crusader Defender attacks")
		shieldBashTimer.wait_time = shieldbash_attackspeed * (1 - spell_cooldown)
		if shieldBashTimer.is_stopped():
			shieldBashTimer.start()
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown)					
		if tornadoTimer.is_stopped():
			tornadoTimer.start()				
	elif champion_spec == "Lightbringer":  # Crusader - Lightbringer
		print("starting Lightbringer attacks")
		holySmiteTimer.wait_time = holysmite_attackspeed * (1 - spell_cooldown)
		if holySmiteTimer.is_stopped():
			holySmiteTimer.start()
		shieldBashTimer.wait_time = shieldbash_attackspeed * (1 - spell_cooldown)
		if shieldBashTimer.is_stopped():
			shieldBashTimer.start()	
	elif champion_spec == "Water":  # Shaman - Water (Healing)
		print("starting Water Shaman attacks")		
		holySmiteTimer.wait_time = holysmite_attackspeed * (1 - spell_cooldown)
		if holySmiteTimer.is_stopped():
			holySmiteTimer.start()
		iceSpearTimer.wait_time = icespear_attackspeed * (1 - spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()				
	elif champion_spec == "Earth":  # Shaman - Earth (Tank)
		print("starting Earth Shaman attacks")
		shieldBashTimer.wait_time = shieldbash_attackspeed * (1 - spell_cooldown)
		if shieldBashTimer.is_stopped():
			shieldBashTimer.start()
		tornadoTimer.wait_time = tornado_attackspeed * (1 - spell_cooldown)					
		if tornadoTimer.is_stopped():
			tornadoTimer.start()					
	elif champion_spec == "Necromancer":  # Wizard - Necromancer
		print("starting Necromancer attacks")
		shadowBoltTimer.wait_time = shadowbolt_attackspeed * (1 - spell_cooldown)
		if shadowBoltTimer.is_stopped():
			shadowBoltTimer.start()
		shadowStrikeTimer.wait_time = shadowstrike_attackspeed * (1 - spell_cooldown)
		if shadowStrikeTimer.is_stopped():
			shadowStrikeTimer.start()	
	else:
		print("No attack found for specialization: ", champion_spec)

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()
	play_attack_animation()	


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
#		icespear_attack.level = icespear_level
		icespear_attack.caster = self
		print( champion_name, " is casting Ice Spear with attack_power: ", attack_power )		
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()	


func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo # + additional_attacks
	tornadoAttackTimer.start()
	play_attack_animation()	

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
#		tornado_attack.level = tornado_level
		tornado_attack.caster = self
		print( champion_name, " is casting Tornado Attack with attack_power: ", attack_power )
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()	



func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#Upgrade javelin
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()
		
				
func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else: 
		return Vector2.UP
		

func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)


func _on_grab_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		area.target = self


#func _on_collect_area_area_entered(area: Area2D) -> void:
#	if area.is_in_group("loot"):
#		var gem_exp = area.collect()
#		calculate_experience(gem_exp)

func _on_collect_area_area_entered(area: Area2D) -> void:
	if not area.is_in_group("loot"):
		return

	var payload = area.collect()

	if typeof(payload) == TYPE_DICTIONARY:
		var ptype = payload.get("type", "")
		if ptype == "item":
			var item = payload.get("item", null)
			if item != null:
				# Find the crawler world (put crawler world in a group for easy lookup once)
				var world = get_tree().get_first_node_in_group("dungeon_world")
				if world and world.has_method("try_add_item_to_dungeon_inventory"):
					var ok = world.try_add_item_to_dungeon_inventory(item)
					if not ok:
						# optional: spawn message "Inventory full"
						pass
		elif ptype == "xp":
			var xp_amount = int(payload.get("amount", 0))
			calculate_experience(xp_amount) # your old path


func calculate_experience(gem_exp):
#	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
#	if experience + collected_experience >= exp_required: #level up
#		collected_experience -= exp_required - experience
#		experience_level += 1
#		experience = 0
#		exp_required = calculate_experiencecap()
#		levelup()

#	else:
#		experience += collected_experience
#		collected_experience = 0
			
#	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap + 95 * (experience_level-19)*8
	else:
		exp_cap = 255 * (experience_level-39)*12
		
	return exp_cap
					
#func set_expbar(set_value = 1, set_max_value = 100):
#	expBar.value = set_value
#	expBar.max_value = set_max_value
	
func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(850,400),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1	
	get_tree().paused = true
	
func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)	
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(2000,400)
	get_tree().paused = false
	calculate_experience(0)

func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #check already collected upgrades
			pass
		elif i in upgrade_options: #if upgrade is already an option				 
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Dont pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)		
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null	

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(850,200),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Died"	
		sndLose.play()

func _on_dungeon_completed_panel():
#	deathPanel.visible = true
#	get_tree().paused = true
#	var tween = deathPanel.create_tween()
#	tween.tween_property(deathPanel,"position",Vector2(850,200),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
#	tween.play()
	lblResult.text = "You Win"
	sndVictory.play()

func _on_player_death_panel():
	deathPanel.visible = true
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(850,200),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	lblResult.text = "You Died"
	#sndVictory.play() -- change to death sound


func _on_btn_menu_click_end():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://dungeons_play_scene.tscn")


func _on_berserker_slash_timer_timeout():
	berserker_slash_ammo += berserker_slash_baseammo + additional_attacks
	berserkerSlashAttackTimer.start()
	play_attack_animation()	

func _on_berserker_slash_attack_timer_timeout():
	if berserker_slash_ammo > 0:
		var berserkerSlash_attack = berserker_slash.instantiate()
		berserkerSlash_attack.position = position
		berserkerSlash_attack.target = get_random_target()
		berserkerSlash_attack.caster = self
		print( champion_name, " is casting Berserker Slash with attack_power: ", attack_power )		
		add_child(berserkerSlash_attack)
		berserker_slash_ammo -= 1
		if berserker_slash_ammo > 0:
			berserkerSlashAttackTimer.start()
		else:
			berserkerSlashAttackTimer.stop()	


func _on_fire_blast_timer_timeout():
	fireblast_ammo += fireblast_baseammo + additional_attacks
	fireBlastAttackTimer.start()
	play_attack_animation()		


func _on_fire_blast_attack_timer_timeout() -> void:
	if fireblast_ammo > 0:
		var fireBlast_attack = fire_blast.instantiate()
		fireBlast_attack.position = position
		fireBlast_attack.target = get_random_target()
		fireBlast_attack.caster = self
		print( champion_name, " is casting Fire Blast with attack_power: ", attack_power )		
		add_child(fireBlast_attack)
		fireblast_ammo -= 1
		if fireblast_ammo > 0:
			fireBlastAttackTimer.start()
		else:
			fireBlastAttackTimer.stop()	


func _on_shadow_strike_timer_timeout():
	shadowstrike_ammo += shadowstrike_baseammo + additional_attacks
	shadowStrikeAttackTimer.start()
	play_attack_animation()	

func _on_shadow_strike_attack_timer_timeout():
	if shadowstrike_ammo > 0:
		var shadowStrike_attack = shadow_strike.instantiate()
		shadowStrike_attack.position = position
		shadowStrike_attack.target = get_random_target()
		shadowStrike_attack.caster = self
		print( champion_name, " is casting Shadow Strike with attack_power: ", attack_power )			
		add_child(shadowStrike_attack)
		shadowstrike_ammo -= 1
		if shadowstrike_ammo > 0:
			shadowStrikeAttackTimer.start()
		else:
			shadowStrikeAttackTimer.stop()	


func _on_shadow_bolt_timer_timeout():
	shadowbolt_ammo += shadowbolt_baseammo + additional_attacks
	shadowBoltAttackTimer.start()
	play_attack_animation()	

func _on_shadow_bolt_attack_timer_timeout():
	if shadowbolt_ammo > 0:
		var shadowBolt_attack = shadow_bolt.instantiate()
		shadowBolt_attack.position = position
		shadowBolt_attack.target = get_random_target()
		shadowBolt_attack.caster = self
		print( champion_name, " is casting Shadow Bolt with attack_power: ", attack_power )			
		add_child(shadowBolt_attack)
		shadowbolt_ammo -= 1
		if shadowbolt_ammo > 0:
			shadowBoltAttackTimer.start()
		else:
			shadowBoltAttackTimer.stop()	


func _on_holy_smite_timer_timeout():
	holysmite_ammo += holysmite_baseammo + additional_attacks
	holySmiteAttackTimer.start()
	play_attack_animation()	

func _on_holy_smite_attack_timer_timeout():
	if holysmite_ammo > 0:
		var holySmite_attack = holy_smite.instantiate()
		holySmite_attack.position = position
		holySmite_attack.target = get_random_target()
		holySmite_attack.caster = self
		print( champion_name, " is casting Holy Smite with attack_power: ", attack_power )
		add_child(holySmite_attack)
		holysmite_ammo -= 1
		if shadowbolt_ammo > 0:
			holySmiteAttackTimer.start()
		else:
			holySmiteAttackTimer.stop()	


func _on_shield_bash_timer_timeout():
	shieldbash_ammo += shieldbash_baseammo + additional_attacks
	shieldBashAttackTimer.start()
	play_attack_animation()	

func _on_shield_bash_attack_timer_timeout():
	if shieldbash_ammo > 0:
		var shieldBash_attack = shield_bash.instantiate()
		shieldBash_attack.position = position
		shieldBash_attack.target = get_random_target()
		shieldBash_attack.caster = self
		print( champion_name, " is casting Shield Bash with attack_power: ", attack_power )				
		add_child(shieldBash_attack)
		shieldbash_ammo -= 1
		if shieldbash_ammo > 0:
			shieldBashAttackTimer.start()
		else:
			shieldBashAttackTimer.stop()	
