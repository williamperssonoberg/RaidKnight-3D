# Champion.gd


class_name Champion

extends Object

var champion_name := ""
var champion_skill: int
var champion_race: String
var champion_class: String
var champion_specialization: String
var champion_xp: int
var champion_xp_level: int
var champion_item_level: int
var champion_power: float
var champion_status: String = "Idle"
var xp_time_accumulator: float = 0
var profession_skill: String
var champion_rarity: String
var skillful_skill: String
var champion_teamwork_rating: int
var champion_reflexes_rating: int
var champion_offense_rating: int
var champion_defense_rating: int
var champion_endurance_rating: int
var champion_focus_rating: int
var champion_morale: int = 1000  # Initial morale points
var specialization_texture: AtlasTexture
var champion_label
var champion_strength
var champion_agility
var champion_intellect
var champion_stamina
var champion_maxhp
var champion_hp	

func _init():
	champion_name = ""
	champion_skill = 0
	champion_race = ""
	champion_class = ""
	champion_xp = 1
	champion_xp_level = 1
	champion_item_level = 1
	calculate_champion_power()
	champion_specialization = ""
	profession_skill = "None"
	champion_rarity = ""
	skillful_skill = "None"
	champion_teamwork_rating = 0
	champion_reflexes_rating = 0
	champion_offense_rating = 0
	champion_defense_rating = 0
	champion_endurance_rating = 0
	champion_focus_rating = 0
	champion_morale = 1000  # Initial morale points
	#specialization_texture
	champion_label  = "None"
	champion_strength = 0
	champion_agility = 0
	champion_intellect = 0
	champion_stamina = 0
	champion_maxhp = 80
	champion_hp	= 80

	
# Add additional attributes and methods as needed

const ItemDatabase = preload("res://ItemDatabase.gd")

#func champion_name_spec_init(name: String, texture: AtlasTexture):

var tile_texture = preload("res://textures/RaidTileSet.png")

func create_champion_label(champion) -> Button:
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(175, 30)  # Set minimum button size
	
	# Create HBoxContainer to hold the label and icon
	var container = HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 8)  # Adds spacing between label and icon
	
	# Create and add Label for Champion Name + XP Level
	var label = Label.new()
	label.text = champion.champion_name + " (" + str(champion.champion_xp_level) + ")"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(label)
	
	# Create TextureRect for Specialization Icon
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(16, 16)
	
	if specialization_atlas_coords.has(champion.champion_specialization):
		var atlas_coords = specialization_atlas_coords[champion.champion_specialization]
		
		var symbol_texture = AtlasTexture.new()
		symbol_texture.atlas = tile_texture
		symbol_texture.region = Rect2(
			atlas_coords.x * 16, atlas_coords.y * 16,
			16, 16
		)
		
		texture_rect.texture = symbol_texture
	else:
		print("Warning: No specialization symbol found for ", champion.champion_specialization)
	
	container.add_child(texture_rect)
	
	# Set button background color based on champion's class
	match champion.champion_class:
		"Rogue":
			button.modulate = Color("#FFF468")
		"Priest":
			button.modulate = Color("#FFFFFF")
		"Fighter":
			button.modulate = Color("#C69B6D")
		"Crusader":
			button.modulate = Color("#F48CBA")
		"Shaman":
			button.modulate = Color("#0070DD")
		"Wizard":
			button.modulate = Color("#8788EE")
		_:
			button.modulate = Color(1, 1, 1)  # Default color

	# Add container (with label and texture) to the button
	button.add_child(container)
	
	return button


var specialization_atlas_coords = {
	"TANK": Vector2i(7, 0),   # Tile at (7, 0)
	"Soldier": Vector2i(7, 0),
	"Defender": Vector2i(7, 0),
	"Earth": Vector2i(7, 0),
	"HEALER": Vector2i(8, 0), # Tile at (8, 0)
	"Lightbringer": Vector2i(8, 0),
	"Divine": Vector2i(8, 0),
	"Water": Vector2i(8, 0),
	"DPS": Vector2i(6, 0),    # Tile at (6, 0)
	"Berserker": Vector2i(6, 0),
	"Voodoo": Vector2i(6, 0),
	"Wind": Vector2i(6, 0),
	"Fire": Vector2i(6, 0),
	"Necromancer": Vector2i(6, 0),
	"Stalker": Vector2i(6, 0)
}


# Function to add XP to the champion
func add_xp(amount: int):
	champion_xp += amount

   # Print a message indicating the XP gain
	#if amount > 0:
	#	print(champion_name + " gained " + str(amount) + " XP")

func calculate_champion_power():
	champion_power = champion_xp_level + champion_item_level * (champion_skill / 100.0)
	return champion_power

#----------------------------------------------------- ITEMS

# Equipment slots - initially empty
var equipment_slots = {
	"Helmet": null,
	"Neck": null,
	"Shoulders": null,
	"Cloak": null,
	"Chest": null,
	"Armguards": null,
	"Gloves": null,
	"Belt": null,
	"Legs": null,
	"Boots": null,
	"Ring1": null,
	"Ring2": null,
	"Trinket1": null,
	"Trinket2": null,
	"MainHand": null,
	"OffHand": null
}


# Equip item function
func equip_item(item: ItemDatabase.Item):
	# Check if item meets level requirements
	if item.required_level > champion_xp_level:
		print("Champion level too low to equip ", item.item_name)
		return

	# Equip to appropriate slot
	if item.item_type in equipment_slots:
		equipment_slots[item.item_type] = item
		print(item.item_name, " equipped to ", item.item_type)
	else:
		print("Invalid slot for item: ", item.item_type)

	# Recalculate item level
	update_champion_item_level()



func try_equip_item(item: ItemDatabase.Item) -> bool:
	if equipment_slots.has(item.item_type):
		var equipped_item = equipment_slots[item.item_type]
		if equipped_item == null or equipped_item.item_level < item.item_level:
			equipment_slots[item.item_type] = item
			print(champion_name, " equipped ", item.item_name, " (iLvl ", item.item_level, ")")
			return true
	return false

# Update total item level
func update_champion_item_level():
	champion_item_level = 0
	for slot in equipment_slots.values():
		if slot != null:
			champion_item_level += slot.item_level
	print("Updated Champion item level: ", champion_item_level)


# Utility function to create a champion button
func create_champion_button(champion) -> Button:
	# Create a new button
	var champion_button = Button.new()
	var champion_label = Label.new()
	
	champion_button.text = champion.champion_name + " (" + str(champion.champion_xp_level) + ")"
	
	#champion_button.size = Vector2(300, 30)
	
	# Atlas coordinates for specialization symbols
	var specialization_atlas_coords = {
		"TANK": Vector2i(7, 0),   # Tile at (7, 0)
		"Soldier": Vector2i(7, 0),
		"Defender": Vector2i(7, 0),
		"Earth": Vector2i(7, 0),
		"HEALER": Vector2i(8, 0), # Tile at (8, 0)
		"Lightbringer": Vector2i(8, 0),
		"Divine": Vector2i(8, 0),
		"Water": Vector2i(8, 0),
		"DPS": Vector2i(6, 0),    # Tile at (6, 0)
		"Berserker": Vector2i(6, 0),
		"Voodoo": Vector2i(6, 0),
		"Wind": Vector2i(6, 0),
		"Fire": Vector2i(6, 0),
		"Necromancer": Vector2i(6, 0),
		"Stalker": Vector2i(6, 0)
	}
	# Set background color based on champion's class
	match champion.champion_class:
		"Rogue":
			champion_button.modulate = Color("#FFF468")
		"Priest":
			champion_button.modulate = Color("#FFFFFF")
		"Fighter":
			champion_button.modulate = Color("#C69B6D")
		"Crusader":
			champion_button.modulate = Color("#F48CBA")
		"Shaman":
			champion_button.modulate = Color("#0070DD")
		"Wizard":
			champion_button.modulate = Color("#8788EE")
		_:
			# Default color if champion class is not recognized
			champion_button.modulate = Color(1, 1, 1)  # White


	# Add specialization symbol
	var symbol_texture_rect = TextureRect.new()
	symbol_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol_texture_rect.custom_minimum_size = Vector2(16, 16)
	symbol_texture_rect.self_modulate = Color(1, 1, 1, 1)
	symbol_texture_rect.z_index = 1

	# Find and assign the specialization symbol from the dictionary
	var specialization = champion.champion_specialization
	if specialization_atlas_coords.has(specialization):
		var atlas_coords = specialization_atlas_coords[specialization]
		# Load the base texture (e.g., sprite sheet)
# Create an AtlasTexture

		
		
		var base_texture = load("res://textures/RaidTileSet.png")
		var symbol_texture = AtlasTexture.new()
		symbol_texture.atlas = base_texture  # Set the base texture
		symbol_texture.region = Rect2(
			atlas_coords.x * 16, atlas_coords.y * 16,
			16, 16
		)
		symbol_texture_rect.texture = symbol_texture
	else:
		print("Warning: No symbol found for specialization ", specialization)
	
	# Add the TextureRect as a child of the button
	#champion_button.add_child(champion_label)
	champion_button.add_child(symbol_texture_rect)
	symbol_texture_rect.position = Vector2(champion_button.size.x + 200, 10)
	

	return champion_button


signal champion_stats_changed

func recalc_combat_stats() -> void:
	# Recompute item level / power / derived stats
	print("Called recalc_combat_stats for: ", champion_name, " with new ilvl ", champion_item_level)
	calculate_champion_power()  # or recompute item level sum
	champion_strength = champion_item_level
	champion_agility = champion_item_level
	champion_intellect = champion_item_level
	champion_stamina = champion_item_level

	var champion_old_maxhp = champion_maxhp
	champion_maxhp = champion_stamina * 10
	# keep %hp when max changes (optional, but feels good)
	if champion_old_maxhp > 0:
		var pct = champion_hp / champion_old_maxhp
		champion_hp = clamp(pct * champion_maxhp, 1.0, champion_maxhp)
	else:
		champion_hp = champion_maxhp

	emit_signal("champion_stats_changed")

func get_skillful_multiplier() -> float:

	match skillful_skill:
		"None":
			return 1.0
		"Skillful_Healer":
			return 1.05 if champion_specialization in ["Lightbringer","Divine","Water"] else 1.0
		"Skillful_Tank":
			return 1.05 if champion_specialization in ["Defender","Soldier","Earth"] else 1.0
		"Skillful_Melee_DPS":
			return 1.05 if champion_specialization in ["Berserker","Stalker","Wind"] else 1.0
		"Skillful_Ranged_DPS":
			return 1.05 if champion_specialization in ["Voodoo","Fire","Scholar","Necromancer"] else 1.0

	return 1.0
