extends Node2D
@export var room_size: float = 1280.0  # same as ROOM_SIZE in crawler_world
@onready var sprite: Sprite2D = $Sprite2D  # Ensure this path is correct
@onready var floor_tilemap: TileMap = $FloorTileMap
#@onready var wall_left: Node2D  = $WallLeft
#@onready var wall_right: Node2D = $WallRight
#@onready var wall_up: Node2D    = $WallUp
#@onready var wall_down: Node2D  = $WallDown


func _ready():
	print_tree()
#	print("Gonna print tree for dungeon room")


#	if sprite:
#		print("✅ Dungeon Room Loaded Successfully: ", name)
#	else:
#		print("❌ ERROR: Sprite2D not found in ", name)



func setup_walls(neighbors: Dictionary) -> void:
	# neighbors has keys: "left", "right", "up", "down" with bools
	$WallLeft.visible = not neighbors.left
	$WallRight.visible = not neighbors.right
	$WallUp.visible = not neighbors.up
	$WallDown.visible = not neighbors.down

	$WallLeft.get_node("CollisionShape2D").disabled = neighbors.left
	$WallRight.get_node("CollisionShape2D").disabled = neighbors.right
	$WallUp.get_node("CollisionShape2D").disabled = neighbors.up
	$WallDown.get_node("CollisionShape2D").disabled = neighbors.down

func set_as_goal():
	if get_child_count() > 0:
		floor_tilemap = get_child(0)
		if floor_tilemap is TileMap:
			floor_tilemap.modulate = Color(1.0, 0.85, 0.5, 1.0)  # warm yellow 
			print("🏁 Goal room tint applied to: ", name)
			var goalFlag = get_node("%GoalFlag")
			goalFlag.visible = true
		else:
			print("❌ ERROR: FloorTileMap not found in ", name)
	else:
		print("❌ ERROR: DungeonRoom has NO children")

#func set_as_goal():
#	if get_child_count() > 0:
#		sprite = get_child(0)  # Gets the first child
#		if sprite and sprite is Sprite2D:
#			sprite.modulate = Color(1, 1, 0.5)  # Mark goal room
#			var goalFlag = get_node("%GoalFlag")
#			goalFlag.visible = true
#		else:
#			print("❌ ERROR: First child is NOT a Sprite2D")
#	else:
#		print("❌ ERROR: DungeonRoom has NO children")
