extends Area2D

@export var experience = 1

var spr_green = preload("res://textures/Items/Gems/Gem_green.png") #uncommon
var spr_blue = preload("res://textures/Items/Gems/Gem_blue.png") #rare
var spr_red = preload("res://textures/Items/Gems/Gem_red.png") #unused
var spr_purple = preload("res://textures/Items/Gems/Gem_purple.png") #epic
var spr_orange = preload("res://textures/Items/Gems/Gem_orange.png") #legendary

var target = null
var speed = -1

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var sound = $snd_collected

func _ready():
	# Decide sprite based on payload
	if is_item:
		_set_texture_for_rarity(item_rarity)
	else:
		# legacy XP coloring if ever used
		if experience < 5:
			sprite.texture = spr_green
		elif experience < 25:
			sprite.texture = spr_blue
		else:
			sprite.texture = spr_red	

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta
		
		
func collect():
	sound.play()
	collision.call_deferred("set", "disabled", true)
	sprite.visible = false

	if is_item:
		# Return an item payload
		return {"type": "item", "item": item_data, "rarity": item_rarity}
	else:
		# Return XP payload (legacy)
		return {"type": "xp", "amount": experience}


func _on_snd_collected_finished() -> void:
	queue_free()

# NEW: item payload
var is_item := false
var item_data = null
var item_rarity := "uncommon"  # "uncommon" | "rare" | "epic" | "legendary"


# Called by enemy to convert this gem into an item gem
func set_item_payload(item, rarity: String) -> void:
	is_item = true
	item_data = item
	item_rarity = rarity

func _set_texture_for_rarity(r: String) -> void:
	match r:
		"legendary":
			sprite.texture = spr_orange
		"epic":
			sprite.texture = spr_purple
		"rare":
			sprite.texture = spr_blue
		_:
			sprite.texture = spr_green
