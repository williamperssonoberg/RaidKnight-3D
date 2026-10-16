extends Node2D

func _ready():
	var tween = Tween.new()  # Create Tween
	print("Tween created: ", tween)
	add_child(tween)  # Add to the scene tree
	print("Tween added successfully.")
