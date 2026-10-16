extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@export var xp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var death_anim = preload("res://enemy/explosion.tscn")

var loot_gem_scene = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)


func _ready():
	anim.play("walk")
	hitBox.damage = enemy_damage
	add_to_group("enemies")

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false	

# enemy.gd
signal enemy_defeated(xp:int)

func death():
	emit_signal("remove_from_array",self)
	# Send XP up to the scene that handles distribution
	emit_signal("enemy_defeated", xp)	
	
		# --- Drop roll (10% gate) ---
	if randf() < 0.10:
		var level = enemy_level
		var rarity := _roll_rarity_for_level(level)
		var item := ItemDatabase.get_random_item_by_rarity(rarity, level)


		if item != null:
			var gem := loot_gem_scene.instantiate()
			gem.global_position = global_position
			# tell the gem: this is an ITEM payload (not XP)
			gem.set_item_payload(item, rarity) # we'll add this method below
			gem.add_to_group("loot")          # keep same group so pickup code sees it
			get_parent().call_deferred("add_child", gem)
	
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = sprite.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child",enemy_death)

	queue_free()

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

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		death()
	else:
		snd_hit.play()

var enemy_level = 1

func set_level(level):
	enemy_level = max(level, 1)  # Ensure minimum level of 1
	update_stats()

func update_stats():
	# Adjust stats based on level
	hp = 10 + (enemy_level * 10)
	xp = 10 + (enemy_level * 10)
	enemy_damage = 1 + (enemy_level * 2)
	movement_speed = 40 + (enemy_level * 0.05)

	print("🧟 Enemy Level: ", enemy_level, "| Health: ", hp, "| XP: ", xp, "| Damage: ", enemy_damage)
