extends CharacterBody2D

@export var follow_speed: float = 500.0
@export var stop_distance: float = 10.0

var follow_target_position: Vector2

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
		print("Attack animation finished! Extra Player and changed the is_attacking value to " + str(is_attacking))

		# go back to an appropriate movement anim next frame

func play_attack_animation():
	if is_attacking:
		#print("Didn't attack because it was already playing Extra Player. is_attacking value is " + str(is_attacking))
		return  # don't restart it constantly
	is_attacking = true
	play_anim("basic_attack_1")
		# wait for the animation to finish once, then unlock
	var anim_player: AnimationPlayer = character_instance.get_node("AnimationPlayer")
	if anim_player:
		anim_player.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
	#print("Executed attack animation func. Extra Player")

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

	# Assign Attack Power based on specialization
	match champion_data.champion_specialization:
		"Stalker":  # Rogue
			attack_power = agility * 2
			attack_scene = shadow_strike
		"Divine":  # Priest
			attack_power = intellect * 1.5
			attack_scene = holy_smite
		"Voodoo":  # Priest (Shadow)
			attack_power = intellect * 1.8
			attack_scene = shadow_bolt
		"Soldier":  # Fighter (Balanced)
			attack_power = strength * 2
			attack_scene = shield_bash
		"Berserker":  # Fighter (Aggressive)
			attack_power = strength * 2.5
			attack_scene = berserker_slash
		"Defender":  # Crusader (Tank)
			attack_power = strength * 1.5
			attack_scene = shield_bash
		"Lightbringer":  # Crusader (Support)
			attack_power = intellect * 1.5
			attack_scene = holy_smite
		"Water":  # Shaman (Healing)
			attack_power = intellect * 1.5
			attack_scene = holy_smite
		"Earth":  # Shaman (Tank)
			attack_power = strength * 1.8
			attack_scene = shield_bash
		"Wind":  # Shaman (Ranged)
			attack_power = agility * 2
			attack_scene = tornado
		"Fire":  # Shaman (Spell DPS)
			attack_power = intellect * 2
			attack_scene = fire_blast
		"Necromancer":  # Wizard
			attack_power = intellect * 2.2
			attack_scene = shadow_bolt

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
	print("_on_champion_stats_changed called for follower: ", champion.champion_name, " with new ilvl ", champion.champion_item_level)
	
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
		get_tree().current_scene.add_child(attack_instance)  # Ensure it's added to the main scene, not under the leader
		attack_instance.global_position = self.global_position  # Use the correct champion position

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
@onready var expBar = get_node("%ExperienceBar")
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
var _last_pos: Vector2
var walking := false

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
	_on_hurt_box_hurt(0,0,0)

@export var follow_target: Node2D
@export var follow_offset: Vector2 = Vector2.ZERO

func set_follow_target_position(pos: Vector2) -> void:
	follow_target_position = pos

func _physics_process(delta: float) -> void:
	var to_target = follow_target_position - global_position
	var dist = to_target.length()

	if dist <= stop_distance:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * follow_speed

	move_and_slide()
	_update_flip()
#	_update_anim()
	var moved_dist := global_position.distance_to(_last_pos)
	_last_pos = global_position
	var speed: float = moved_dist / max(delta, 0.0001)

	# use hysteresis again
	if not walking and speed > 5.0:
		walking = true
	elif walking and speed < 1.0:
		walking = false

	if not is_attacking:
		play_anim("walk" if walking else "Idle")	
#	if not follow_target:
#		return

const WALK_ON  := 10.0
const WALK_OFF := 5.0


func _update_anim() -> void:
	if is_attacking:
		return
	var real_speed := get_real_velocity().length()

	# hysteresis prevents flicker
	if not walking and real_speed > WALK_ON:
		walking = true
	elif walking and real_speed < WALK_OFF:
		walking = false

	if walking:
		play_anim("walk")
	else:
		play_anim("Idle")		

@onready var visual_root: Node2D = $CharacterContainer/CharacterHolder

func _update_flip():
	if abs(velocity.x) < 5:
		return

	visual_root.scale.x = -1 if velocity.x > 0 else 1

#	var target_pos: Vector2 = follow_target.global_position + follow_offset
#	var to_target: Vector2 = target_pos - global_position
#	var distance := to_target.length()

#	if distance > stop_distance:
#		velocity = to_target.normalized() * follow_speed
#	else:
#		velocity = Vector2.ZERO

#	move_and_slide()

	
	
#func movement():
#	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
#	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
#	var mov = Vector2(x_mov,y_mov)
#	if mov.x > 0:
#		sprite.scale.x = -1  # Flip left ist för flip_h = true
#	elif mov.x < 0:
#		sprite.scale.x = 1   # Flip right ist för flip_h = false
		
#	if mov != Vector2.ZERO:
#		last_movement = mov
		#if walkTimer.is_stopped():
		#	if sprite.frame >= sprite.hframes -1:
		#		sprite.frame = 0
		#	else:
		#		sprite.frame += 1
		#	walkTimer.start()		
		
#	velocity = mov.normalized()*movement_speed
#	if is_attacking:
#		return  # don't override attack with walk/idle
#	if mov.x != 0:
#		play_anim("walk")
#	else:
#		play_anim("Idle") 
	
#	move_and_slide()

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
		icespear_attack.global_position = global_position  
		icespear_attack.target = get_random_target()
#		icespear_attack.level = icespear_level
		icespear_attack.caster = self
		print( champion_name, " is casting Ice Spear with attack_power: ", attack_power )		
		get_tree().current_scene.add_child(icespear_attack)
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
		tornado_attack.global_position = global_position  
		tornado_attack.last_movement = last_movement
		tornado_attack.caster = self
		print( champion_name, " is casting Tornado Attack with attack_power: ", attack_power )				
#		tornado_attack.level = tornado_level
		get_tree().current_scene.add_child(tornado_attack)
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






func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)


func death_old_function_dont_use():
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
		lblResult.text = "You Lose"	
		sndLose.play()

func death():
	print("You Died")
	# Example: Change Scene or Show Victory UI
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.death()
	else:
		print("❌ Player not found to trigger dungeon complete.")



func _on_berserker_slash_timer_timeout():
	berserker_slash_ammo += berserker_slash_baseammo + additional_attacks
	berserkerSlashAttackTimer.start()
	play_attack_animation()	

func _on_berserker_slash_attack_timer_timeout():
	if berserker_slash_ammo > 0:
		var berserkerSlash_attack = berserker_slash.instantiate()
		berserkerSlash_attack.global_position = global_position  
		berserkerSlash_attack.target = get_random_target()
		berserkerSlash_attack.caster = self
		print( champion_name, " is casting Berserker Slash with attack_power: ", attack_power )				
		get_tree().current_scene.add_child(berserkerSlash_attack)
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
		fireBlast_attack.global_position = global_position  
		fireBlast_attack.target = get_random_target()
		fireBlast_attack.caster = self
		print( champion_name, " is casting Fire Blast with attack_power: ", attack_power )					
		get_tree().current_scene.add_child(fireBlast_attack)
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
		shadowStrike_attack.global_position = global_position  
		shadowStrike_attack.target = get_random_target()
		shadowStrike_attack.caster = self
		print( champion_name, " is casting Shadow Strike with attack_power: ", attack_power )		
		get_tree().current_scene.add_child(shadowStrike_attack)
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
		shadowBolt_attack.global_position = global_position  
		shadowBolt_attack.target = get_random_target()
		shadowBolt_attack.caster = self
		print( champion_name, " is casting Shadow Bolt with attack_power: ", attack_power )	
		get_tree().current_scene.add_child(shadowBolt_attack)
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
		holySmite_attack.global_position = global_position 
		holySmite_attack.target = get_random_target()
		holySmite_attack.caster = self
		print( champion_name, " is casting Holy Smite with attack_power: ", attack_power )
		get_tree().current_scene.add_child(holySmite_attack)
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
		shieldBash_attack.global_position = global_position  
		shieldBash_attack.target = get_random_target()
		shieldBash_attack.caster = self
		print( champion_name, " is casting Shield Bash with attack_power: ", attack_power )		
		get_tree().current_scene.add_child(shieldBash_attack)
		shieldbash_ammo -= 1
		if shieldbash_ammo > 0:
			shieldBashAttackTimer.start()
		else:
			shieldBashAttackTimer.stop()	
