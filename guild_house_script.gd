extends Node
var GlobalData

# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalData = get_node("/root/GlobalData")
	
	GlobalData.connect("currency_changed", Callable(self, "update_currency_display"))
	# Initial update to display the starting currency
	update_currency_display()  # Initial update to display starting currency

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _on_go_to_city_view_pressed():
	get_tree().change_scene_to_file("res://main_scene.tscn")
	
	


func _on_go_to_recruitment_pressed():
	get_tree().change_scene_to_file("res://recruitment.tscn")
	


func _on_go_to_guild_upgrades_pressed():
	get_tree().change_scene_to_file("res://guild_upgrades_scene.tscn")
	


func _on_go_to_roster_pressed():
	get_tree().change_scene_to_file("res://guild_roster_scene.tscn")


func update_currency_display():
	var currency = GlobalData.get_currency()
	var gold = currency[0]
	var silver = currency[1]
	var copper = currency[2]
	$Control/copper_total_label.text = "Gold: %d Silver: %d Copper: %d" % [gold, silver, copper]
	


func _on_add_99_copper_button_pressed():
	GlobalData.add_copper(99) # Add 99 Copper
	update_currency_display()
