extends Node2D

# ---------------------------------------------------------
# CONFIG / EXPORTS
# ---------------------------------------------------------

@export var body_texture: Texture2D
@export var default_armor_texture: Texture2D   # default armor set (atlas layout)
@export var mainhand_texture: Texture2D
@export var offhand_texture: Texture2D

# movement bounds (used in city scenes)
var movement_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var move_speed: float = 50.0


# champion metadata (set from outside)
var race: String = ""
var champion_class: String = ""

# References to equipment
#var body_texture: Texture2D = null
var armor_texture: Texture2D = null
#var mainhand_texture: Texture2D = null
#var offhand_texture: Texture2D = null

# ---------------------------------------------------------
# NODE REFERENCES
# ---------------------------------------------------------

@onready var body_sprite: Sprite2D = %Body
@onready var armor_sprite: Sprite2D = %Armor
@onready var mainhand_sprite: Sprite2D = %MainHand
@onready var offhand_sprite: Sprite2D = %OffHand
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var head_sprite       : Sprite2D = %HeadSprite
@onready var chest_sprite      : Sprite2D = %ChestSprite
@onready var shoulders_r_sprite  : Sprite2D = %Shoulder_R_Sprite
@onready var shoulders_l_sprite  : Sprite2D = %Shoulder_L_Sprite
@onready var cloak_sprite      : Sprite2D = %CloakSprite
@onready var armguards_sprite  : Sprite2D = %ArmguardsSprite
@onready var gloves_sprite     : Sprite2D = %GlovesSprite
@onready var belt_sprite       : Sprite2D = %BeltSprite
@onready var legs_sprite       : Sprite2D = %LegsSprite
@onready var boots_sprite      : Sprite2D = %BootsSprite
@onready var lower_arm_l_sprite : Sprite2D = %Lower_Arm_L_Sprite
@onready var lower_arm_r_sprite : Sprite2D = %Lower_Arm_R_Sprite
@onready var upper_arm_l_sprite : Sprite2D = %Upper_Arm_L_Sprite
@onready var upper_arm_r_sprite : Sprite2D = %Upper_Arm_R_Sprite
@onready var hand_l_sprite : Sprite2D = %Hand_L_Sprite
@onready var hand_r_sprite : Sprite2D = %Hand_R_Sprite
@onready var upper_leg_l_sprite : Sprite2D = %Upper_Leg_L_Sprite
@onready var upper_leg_r_sprite : Sprite2D = %Upper_Leg_R_Sprite
@onready var lower_leg_l_sprite : Sprite2D = %Lower_Leg_L_Sprite
@onready var lower_leg_r_sprite : Sprite2D = %Lower_Leg_R_Sprite
@onready var foot_l_sprite : Sprite2D = %Foot_L_Sprite
@onready var foot_r_sprite : Sprite2D =  %Foot_R_Sprite


# mapping from logical slot to per-sprite region keys
var armor_mapping := {}   # filled in _ready()


const TILE_SIZE := 32

# x0, y0, x1, y1 in TILE COORDS (inclusive)
const ARMOR_TILE_REGIONS := {
	"Belt":              Vector4i(0, 0,  5,  3),
	"Helm":              Vector4i(6, 0,  9,  3),
	"Hand_R":            Vector4i(10, 0, 12, 3),
	"Hand_L":            Vector4i(13, 0, 15, 3),
	"Upper_Leg_R":       Vector4i(0, 4,  2,  8),
	"Upper_Leg_L":       Vector4i(3, 4,  5,  8),
	"Upper_Arm_R":       Vector4i(6, 7,  7,  8),
	"Upper_Arm_L":       Vector4i(8, 7,  9,  8),
	"Lower_Arm_R":       Vector4i(6, 4,  7,  6),
	"Lower_Arm_L":       Vector4i(8, 4,  9,  6),
	"Chest":             Vector4i(10, 4, 15, 8),
	"Lower_Leg_R":       Vector4i(0, 9,  3, 13),
	"Lower_Leg_L":       Vector4i(4, 9,  7, 13),
	"Foot_R":            Vector4i(0, 14, 3, 15),
	"Foot_L":            Vector4i(4, 14, 7, 15),
	"Shoulder_L":        Vector4i(11, 9, 15, 15),
	"Shoulder_R":        Vector4i(8, 9, 10, 15),
}

func tiles_to_rect(t: Vector4i) -> Rect2:
	var x0 = t.x
	var y0 = t.y
	var x1 = t.z
	var y1 = t.w
	var w = (x1 - x0 + 1) * TILE_SIZE
	var h = (y1 - y0 + 1) * TILE_SIZE
	return Rect2(x0 * TILE_SIZE, y0 * TILE_SIZE, w, h)
	

# ---------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------

var slot_to_sprites := {
	"Head":      [head_sprite],
	"Chest":     [chest_sprite],
	"Shoulders": [shoulders_l_sprite, shoulders_r_sprite],
	"Cloak":     [cloak_sprite],
	"Armguards": [lower_arm_l_sprite, lower_arm_r_sprite, upper_arm_l_sprite, upper_arm_r_sprite],
	"Gloves":    [hand_l_sprite, hand_r_sprite],
	"Belt":      [belt_sprite],
	"Legs":      [upper_leg_l_sprite, upper_leg_r_sprite, lower_leg_l_sprite, lower_leg_r_sprite],
	"Boots":     [foot_l_sprite, foot_r_sprite],
}


func apply_armor_to_slot(slot: String, armor_set: Dictionary):
	if slot_to_sprites.has(slot):
		for sprite_name in slot_to_sprites[slot]:
			var sprite = sprite_name
			var rect = armor_set[slot][sprite_name.name]  # rects defined per sprite
			sprite.texture = armor_set.texture
			sprite.region_enabled = true
			sprite.region_rect = rect

func _ready() -> void:
	# Apply initial textures if provided
	if body_texture:
		body_sprite.texture = body_texture
	if default_armor_texture:
		# If you want an overall overlay as well, keep this;
		# otherwise you can remove armor_sprite entirely later.
		armor_sprite.texture = default_armor_texture
	if mainhand_texture:
		mainhand_sprite.texture = mainhand_texture
	if offhand_texture:
		offhand_sprite.texture = offhand_texture

	randomize()

	# Build mapping from logical equipment slots to actual sprites & region keys
	armor_mapping = {
		"Head": [
			{"sprite": head_sprite, "region_key": "Helm"},
		],
		"Chest": [
			{"sprite": chest_sprite, "region_key": "Chest"},
		],
		"Shoulders": [
			{"sprite": shoulders_l_sprite, "region_key": "Shoulder_L"},
			{"sprite": shoulders_r_sprite, "region_key": "Shoulder_R"},
		],
		"Cloak": [
			{"sprite": cloak_sprite, "region_key": "Chest"}, # or custom region if you have one
		],
		"Armguards": [
			{"sprite": upper_arm_l_sprite, "region_key": "Upper_Arm_L"},
			{"sprite": upper_arm_r_sprite, "region_key": "Upper_Arm_R"},
			{"sprite": lower_arm_l_sprite, "region_key": "Lower_Arm_L"},
			{"sprite": lower_arm_r_sprite, "region_key": "Lower_Arm_R"},
		],
		"Gloves": [
			{"sprite": hand_l_sprite, "region_key": "Hand_L"},
			{"sprite": hand_r_sprite, "region_key": "Hand_R"},
		],
		"Belt": [
			{"sprite": belt_sprite, "region_key": "Belt"},
		],
		"Legs": [
			{"sprite": upper_leg_l_sprite, "region_key": "Upper_Leg_L"},
			{"sprite": upper_leg_r_sprite, "region_key": "Upper_Leg_R"},
			{"sprite": lower_leg_l_sprite, "region_key": "Lower_Leg_L"},
			{"sprite": lower_leg_r_sprite, "region_key": "Lower_Leg_R"},
		],
		"Boots": [
			{"sprite": foot_l_sprite, "region_key": "Foot_L"},
			{"sprite": foot_r_sprite, "region_key": "Foot_R"},
		],
	}

	
# ---------------------------------------------------------
# RANDOM CITY MOVEMENT (optional)
# ---------------------------------------------------------

func set_movement_bounds(bounds: Rect2) -> void:
	movement_bounds = bounds
	_start_random_movement()

func _start_random_movement() -> void:
	var target_position = Vector2(
		randf_range(movement_bounds.position.x, movement_bounds.position.x + movement_bounds.size.x),
		randf_range(movement_bounds.position.y, movement_bounds.position.y + movement_bounds.size.y)
	)
	interpolate_to_position(target_position)

func interpolate_to_position(target_position: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(
		self, "position", target_position,
		position.distance_to(target_position) / move_speed
	)
	tween.tween_callback(Callable(self, "_start_random_movement"))


# ---------------------------------------------------------
# SIMPLE EQUIP FOR BASE PARTS (body / armor overlay / weapons)
# ---------------------------------------------------------

func equip_item(slot: String, texture: Texture2D) -> void:
	match slot:
		"body":
			body_sprite.texture = texture
		"armor":
			armor_sprite.texture = texture
		"mainhand":
			mainhand_sprite.texture = texture
		"offhand":
			offhand_sprite.texture = texture


# Play an animation
func play_animation(animation_name: String):
	$AnimationPlayer.play(animation_name)

func set_champion_data(data):
	# Set the race and class
	race = data.champion_race
	champion_class = data.champion_class
	print("Setting data for: ", race, " ", champion_class)
	
	# Check if equipment slots are null and assign default textures
	if "MainHand" in data.equipment_slots and data.equipment_slots["MainHand"] == null:
		mainhand_sprite.texture = preload("res://textures/sword1.png")
	
	if "OffHand" in data.equipment_slots and data.equipment_slots["OffHand"] == null:
		offhand_sprite.texture = preload("res://textures/shield1.png")
		
	# Customize the appearance based on race and class
	match race:
		"Human":
			body_sprite.texture = preload("res://textures/default_character.png")
		"Orc":
			body_sprite.texture = preload("res://textures/default_character.png")
		"Dwarf":
			body_sprite.texture = preload("res://textures/default_character.png")
		"Elf":
			body_sprite.texture = preload("res://textures/default_character.png")
		"Undead":
			body_sprite.texture = preload("res://textures/default_character.png")
		"Halfling":
			body_sprite.texture = preload("res://textures/default_character.png")			
		# Add more races as needed
	
	match champion_class:
		"Rogue":
			armor_sprite.texture = preload("res://textures/armour1.png")
		"Priest":
			armor_sprite.texture = preload("res://textures/armour1.png")
		"Fighter":
			armor_sprite.texture = preload("res://textures/armour1.png")
		"Crusader":
			armor_sprite.texture = preload("res://textures/armour1.png")
		"Wizard":
			armor_sprite.texture = preload("res://textures/armour1.png")
		"Shaman":
			armor_sprite.texture = preload("res://textures/armour1.png")

		# Add more classes as needed
	# Debug textures after assignment
	print("Body texture after assignment: ", body_sprite.texture)
	print("Armor texture after assignment: ", armor_sprite.texture)

func _apply_region_to_sprite(sprite: Sprite2D, region_key: String, tex: Texture2D) -> void:
	if tex == null or sprite == null:
		return
	var tile_coords: Vector4i = ARMOR_TILE_REGIONS.get(region_key, Vector4i())
	var rect: Rect2 = tiles_to_rect(tile_coords)
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = rect
	sprite.visible = true

var slot_to_sprite := {}

func apply_armor_piece(slot_name: String, texture_path: String) -> void:
	var sprite: Sprite2D = slot_to_sprite.get(slot_name)
	if not sprite:
		return

	var tex: Texture2D = load(texture_path)
	if tex == null:
		return

	var tile_coords: Vector4i = ARMOR_TILE_REGIONS.get(slot_name, Vector4i())
	var rect: Rect2 = tiles_to_rect(tile_coords)

	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = rect
	sprite.visible = true	

func apply_armor_for_slot(slot_name: String, tex: Texture2D) -> void:
	if tex == null:
		return
	if not armor_mapping.has(slot_name):
		return
	for entry in armor_mapping[slot_name]:
		var sprite: Sprite2D = entry["sprite"]
		var region_key: String = entry["region_key"]
		_apply_region_to_sprite(sprite, region_key, tex)

# Apply one slot, using item texture if present, otherwise the champion's default armor
func apply_armor_slot_from_item(slot_name: String, texture_path: String) -> void:
	var tex: Texture2D = null
	if texture_path != "" and texture_path != null:
		tex = load(texture_path)
	else:
		tex = default_armor_texture
	apply_armor_for_slot(slot_name, tex)
	
# Apply the same armor set to all slots (useful for starting gear / full set)
func apply_full_armor_set(tex: Texture2D) -> void:
	if tex == null:
		return
	for slot_name in armor_mapping.keys():
		apply_armor_for_slot(slot_name, tex)	
