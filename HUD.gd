extends CanvasLayer

@onready var currency_label = $Control/CurrencyLabel
@onready var members_label = $Control/GuildMembersLabel
@onready var guild_power_label = $Control/GuildPowerLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	print("HUD autoload ready")
#	self.connect("tree_entered", _on_HUD_ready)
	#pass # Replace with function body.


#func _on_HUD_ready():
#	print("HUD scene entered the tree")
#	var control = $Control
#	if control:
#		control.set_anchors_preset(Control.PRESET_FULL_RECT)
#		print("HUD control adjusted and ready")
#	else:
#		print("Control node not found!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func update_currency_hud_label(gold: int, silver: int, copper: int):
	currency_label.text = "Gold: %d Silver: %d Copper: %d" % [gold, silver, copper]
	
func update_guild_members_hud_label(members: int):
	members_label.text = "Guild Members: %d" % members

func update_guild_power_hud_label(power: int):
	guild_power_label.text = "Guild Power: %d" % power
