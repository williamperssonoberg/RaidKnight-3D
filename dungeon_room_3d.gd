extends Node3D


func set_as_goal():
	if get_child_count() > 0:
		return
	#	floor_tilemap = get_child(0)
	#	if floor_tilemap is TileMap:
	#		floor_tilemap.modulate = Color(1.0, 0.85, 0.5, 1.0)  # warm yellow 
	#		print("🏁 Goal room tint applied to: ", name)
	#		var goalFlag = get_node("%GoalFlag")
	#		goalFlag.visible = true
	#	else:
#			print("❌ ERROR: FloorTileMap not found in ", name)
#	else:
#		print("❌ ERROR: DungeonRoom has NO children")
