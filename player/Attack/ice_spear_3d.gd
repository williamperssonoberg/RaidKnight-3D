extends Area3D

var caster  # runtime player / extra_player node
var hp = 1
var speed = 10
var damage = 20
var knockback_amount = 0
var attack_size = 1.0

var target = Vector3.ZERO
var direction = Vector3.ZERO

#@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func setup(
	new_caster,
	start_position: Vector3,
	target_position: Vector3
):
	caster = new_caster
	global_position = start_position
	target = target_position

	direction = start_position.direction_to(target_position)
	direction.y = 0.0
	direction = direction.normalized()

	if direction.length() > 0.001:
		look_at(global_position + direction, Vector3.UP)

	damage = calculate_damage()

func _ready():
	pass
	# Get 3D direction from projectile to target
	#direction = global_position.direction_to(target)
	
	# Keep projectile travelling parallel to the ground
	#direction.y = 0.0
	#direction = direction.normalized()

	# Point projectile toward travel direction
	#if direction.length() > 0.001:
	#	look_at(global_position + direction, Vector3.UP)


#	if caster == null:
#		damage = 5
#	else:
##		damage = calculate_damage()

	# Scale projectile
#	scale = Vector3.ONE * attack_size
	
#	if player:  
		# Calculate damage dynamically based on agility
#		var agility_modifier = float(player.agility) / 10.0  # Example: 15 agility → 1.5 modifier
#		var calculated_damage = damage * (1 + agility_modifier)

		# Scale speed dynamically with agility (higher agility = faster attack)
	#	var speed_modifier = float(player.agility) / 20.0  # Example: 20 agility → 1.0 speed boost
	#	speed = speed * (1 + speed_modifier)

		# Scale attack size based on intelligence (optional)
	#	attack_size = 1.0 * (1 + float(player.intellect) / 20.0)  # Example: 20 INT → 1.0x size boost

		# Debug Info
#		print("Icespear Initialized: Damage = ", calculated_damage, " Speed = ", speed, " Size = ", attack_size)

	
#	var tween = create_tween()
#	tween.tween_property(self,"scale",Vector3(1,1,1)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
#	tween.play()

func _physics_process(delta):
	global_position += direction * speed * delta
	
func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array",self)
		queue_free()

func _on_timer_timeout():
	emit_signal("remove_from_array",self)
	queue_free()
	
func calculate_damage() -> float:
	# base spell identity
	var base := 10.0

	# scaling from champion
	var ap = caster.attack_power

	# priest spells scale mostly from intellect / AP
	var coeff := 0.35  # tuning knob

	return base
	#+ (ap * coeff)


func _on_body_entered(body: Node3D):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage, direction, knockback_amount)

		queue_free()
