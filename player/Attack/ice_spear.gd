extends Area2D

var caster  # runtime player / extra_player node
var hp = 1
var speed = 200
var damage = 20
var knockback_amount = 0
var attack_size = 1.0

var target = Vector2.ZERO
var angle = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(135)
	if caster == null:
		damage = 5
	else:
		damage = calculate_damage()
	
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

	
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1,1)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()

func _physics_process(delta):
	position += angle*speed*delta
	
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

	return base + (ap * coeff)
