extends Area2D

var caster 
var hp = 9999
var speed = 100.0
var damage = 20
var attack_size = 1.0
var knockback_amount = 25

var last_movement = Vector2.ZERO
var angle = Vector2.ZERO
var angle_less = Vector2.ZERO
var angle_more = Vector2.ZERO

signal remove_from_array(object)

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	#if player:  
		# Calculate damage dynamically based on agility
		#var agility_modifier = float(player.agility) / 10.0  # Example: 15 agility → 1.5 modifier
		#var calculated_damage = damage * (1 + agility_modifier)

		# Scale speed dynamically with agility (higher agility = faster attack)
	#	var speed_modifier = float(player.agility) / 20.0  # Example: 20 agility → 1.0 speed boost
	#	speed = speed * (1 + speed_modifier)

		# Scale attack size based on intelligence (optional)
	#	attack_size = 1.0 * (1 + float(player.intellect) / 20.0)  # Example: 20 INT → 1.0x size boost

		# Debug Info
		#print("Tornado Initialized: Damage = ", calculated_damage, " Speed = ", speed, " Size = ", attack_size)
	if caster == null:
		damage = 5
	else:
		damage = calculate_damage()

	var move_to_less = Vector2.ZERO
	var move_to_more = Vector2.ZERO
	match last_movement:
		Vector2.UP, Vector2.DOWN:
			move_to_less = global_position + Vector2(randf_range(-1,-0.25), last_movement.y)*500
			move_to_more = global_position + Vector2(randf_range(0.25,1), last_movement.y)*500
		Vector2.RIGHT, Vector2.LEFT:
			move_to_less = global_position + Vector2(last_movement.x, randf_range(-1,-0.25))*500
			move_to_more = global_position + Vector2(last_movement.x, randf_range(0.25,1))*500
		Vector2(1,1), Vector2(-1,-1), Vector2(1,-1), Vector2(-1,-1):
			move_to_less = global_position + Vector2(last_movement.x, last_movement.y * randf_range(0,0.75))*500
			move_to_more = global_position + Vector2(last_movement.x * randf_range(0,0.75), last_movement.y)*500
	
	angle_less = global_position.direction_to(move_to_less)
	angle_more = global_position.direction_to(move_to_more)
	
	var initial_tween = create_tween().set_parallel(true)
	initial_tween.tween_property(self,"scale",Vector2(1,1)*attack_size,3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var final_speed = speed
	speed = speed/5.0
	initial_tween.tween_property(self,"speed",final_speed,6).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	initial_tween.play()
	
	var tween = create_tween()
	var set_angle = randi_range(0,1)
	if set_angle == 1:
		angle = angle_less
		tween.tween_property(self,"angle", angle_more,2)
		tween.tween_property(self,"angle", angle_less,2)
		tween.tween_property(self,"angle", angle_more,2)
		tween.tween_property(self,"angle", angle_less,2)
		tween.tween_property(self,"angle", angle_more,2)
		tween.tween_property(self,"angle", angle_less,2)
	else:
		angle = angle_more	
		tween.tween_property(self,"angle", angle_less,2)
		tween.tween_property(self,"angle", angle_more,2)
		tween.tween_property(self,"angle", angle_less,2)
		tween.tween_property(self,"angle", angle_more,2)
		tween.tween_property(self,"angle", angle_less,2)
		tween.tween_property(self,"angle", angle_more,2)
	tween.play()					
	
func _physics_process(delta):
	position += angle*speed*delta
	
	
func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
	
func calculate_damage() -> float:
	# base spell identity
	var base := 10.0

	# scaling from champion
	var ap = caster.attack_power

	# priest spells scale mostly from intellect / AP
	var coeff := 0.35  # tuning knob

	return base + (ap * coeff)
