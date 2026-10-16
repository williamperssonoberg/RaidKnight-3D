extends Area2D

signal dungeon_completed  # Signal to notify victory

func _ready():
	connect("body_entered", Callable(self, "_on_goal_reached"))

func _on_goal_reached(body):
	if body.is_in_group("player"):  # Ensure only the player triggers it
		print("🎉 Goal reached! Dungeon complete!")
		emit_signal("dungeon_completed")  # Emit signal for external handling
