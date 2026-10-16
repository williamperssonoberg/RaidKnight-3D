extends Area2D


var hp = 1
var speed = 100
var damage = 20
var knockback_amount = 100
var attack_size = 1.0

var target = Vector2.ZERO
var angle = Vector2.ZERO

var caster  # runtime player / extra_player node

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(135)
	if caster == null:
		damage = 5
	else:
		damage = calculate_damage()
	
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
