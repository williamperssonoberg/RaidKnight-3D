extends CharacterBody3D

@export var hp = 10
@export var xp = 10
@export var enemy_damage = 1
@export var movement_speed = 1.0
@onready var hitboxcollision = $HitBoxCollisionShape3D
@onready var snd_hit = $snd_hit

var player: Node3D

var knockback = Vector3.ZERO

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("party_leader")
	if not player:
		print("Enemy: No party leader found!")

func _physics_process(_delta):
	if not player:
		return

	var direction := global_position.direction_to(player.global_position)

	# We only move across the ground.
	direction.y = 0.0
	direction = direction.normalized()

	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	velocity.y = 0.0

	move_and_slide()

	if direction.length() > 0.001:
		look_at(
			global_position + direction,
			Vector3.UP
		)
		
var enemy_level = 1

func take_damage(damage, direction, knockback_amount):
	hp -= damage
	knockback = direction * knockback_amount
	print(
		"Enemy hit for ", damage,
		" | HP remaining: ", hp
	)
	if hp <= 0:
		death()
	else:
		snd_hit.play()

func death():
	emit_signal("remove_from_array",self)
	# Send XP up to the scene that handles distribution
	emit_signal("enemy_defeated", xp)	
	
		# --- Drop roll (10% gate) ---
	if randf() < 0.10:
		var level = enemy_level
		var rarity := _roll_rarity_for_level(level)
		var item := ItemDatabase.get_random_item_by_rarity(rarity, level)



	
#	var enemy_death = death_anim.instantiate()
#	enemy_death.scale = sprite.scale
#	enemy_death.global_position = global_position
#	get_parent().call_deferred("add_child",enemy_death)

	queue_free()

func update_stats():
	# Adjust stats based on level
	hp = 10 + (enemy_level * 10)
	xp = 10 + (enemy_level * 10)
	enemy_damage = 1 + (enemy_level * 2)
	movement_speed = 1 + (enemy_level * 0.05)

	print("🧟 Enemy Level: ", enemy_level, "| Health: ", hp, "| XP: ", xp, "| Damage: ", enemy_damage)

func set_level(level):
	enemy_level = max(level, 1)  # Ensure minimum level of 1
	update_stats()

func _roll_rarity_for_level(lvl:int) -> String:
	if lvl <= 20:
		return "uncommon" # 100% uncommon
	elif lvl <= 40:
		var r := randf()		
		if r < 0.10:
			return "rare"    # next 10%
		else:
			return "uncommon"# remaining 89%
	elif lvl <= 57:
		var r := randf()
		if r < 0.01:     return "epic"    # 1%
		elif r < 0.11:   return "rare"    # next 10%
		else:            return "uncommon"# remaining 89%
	else: # 58-60
		var r2 := randf()
		if r2 < 0.10:    return "epic"    # 10%
		elif r2 < 0.50:  return "rare"    # 40% (0.10..0.50)
		else:            return "uncommon"# 50%

var attack_target: Node3D = null

func _on_hit_box_body_entered(body: Node3D):
	print("Enemy HitBox detected: ", body.name)	
	print("Groups: ", body.get_groups())	
	if body.is_in_group("player"):
		print("Champion entered enemy HitBox: ", body.champion_name)
		attack_target = body
		if $AttackTimer.is_stopped():
			attack()

func _on_hit_box_body_exited(body: Node3D):
	if body == attack_target:
		attack_target = null

func attack():
	if attack_target == null:
		return

	if not is_instance_valid(attack_target):
		attack_target = null
		return

	if attack_target.has_method("take_damage"):
		attack_target.take_damage(enemy_damage)

		print(
			"Enemy attacked ",
			attack_target.champion_name,
			" for ",
			enemy_damage,
			" damage."
		)

		$AttackTimer.start()

func _on_attack_timer_timeout():
	# Cooldown finished.
	# Attack again if target is still inside HitBox.
	if attack_target != null and is_instance_valid(attack_target):
		attack()
