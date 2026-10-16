extends Node

#@onready var global_data = get_node("/root/GlobalData")

# ---------------------------
# Rarity & level helpers
# ---------------------------

static func _normalize_rarity(r: String) -> String:
	if r == null:
		return "uncommon"
	r = r.strip_edges().to_lower()
	# map any synonyms if needed
	if r == "uc": r = "uncommon"
	if r == "r": r = "rare"
	if r == "e": r = "epic"
	return r

static func _display_rarity(r: String) -> String:
	# pretty-case for display/naming
	return r.capitalize()

static func _roll_item_required_level(monster_level: int) -> int:
	return max(1, monster_level + randi_range(-2, 2))

static func _random_item_type() -> String:
	# pick from your slots, but prefer a non-duplicate type if you want later
	return EQUIPMENT_SLOTS[randi() % EQUIPMENT_SLOTS.size()]

static func _generate_item_name(item_type: String, rarity_lc: String, req_level: int) -> String:
	# simple naming you can replace later
	return "%s of the %s (Req %d)" % [item_type, _display_rarity(rarity_lc), req_level]

var items = []


class Item extends RefCounted:
	var item_name: String
	var item_description: String
	var item_type: String  # Helmet, Chest, etc.
	var item_level: int
	var item_rarity: String
	var required_level: int
	var use_item: Callable
	var item_category: String  # NEW: "equipment" or "consumable"
	
	# Default constructor (empty item)
	func _init(name: String = "", description: String = "", use_func: Callable = Callable()):
		item_name = name
		item_description = description
		item_category = "consumable"  # Default to consumable
		use_item = use_func
		
	
		# Constructor for equipment items
	func _init_equipment(name: String, type: String, required_level: int, rarity: String, use_func: Callable = Callable()):
		item_name = name
		item_type = type
		self.required_level = required_level
		item_rarity = rarity
		item_category = "equipment"  # Set as equipment
		item_level = calculate_item_level(rarity, required_level)
		item_description = "A piece of " + item_type + " gear"
		use_item = use_func
		# Constructor for equipment items

	# Calculate item level based on rarity
	func calculate_item_level(rarity: String, base_level: int) -> int:
		var rarity_bonus = {
			"normal": 0,
			"uncommon": 5,
			"rare": 10,
			"epic": 20,
			"legendary": 35
		}
		return base_level + rarity_bonus.get(rarity, 0)


# Example item slots
const EQUIPMENT_SLOTS = ["Helmet", "Neck", "Shoulders", "Cloak", "Chest", "Armguards", "Gloves", "Belt", "Legs", "Boots", "Ring1", "Ring2", "Trinket1", "Trinket2", "MainHand", "OffHand"]

# Generate an epic item for a specific item slot
func generate_epic_item(item_type: String, average_level_required: int) -> Item:
	var item = Item.new()
	item.item_type = item_type
	item.required_level = average_level_required
	item.item_level = average_level_required + 20  # Epic items have +20 item levels
	item.item_rarity = "Epic"
	item.item_name = item_type + " of Triumph"
	
	print("Generated epic item: ", item.item_name, " | Level: ", item.item_level)
	return item

func generate_questing_gear(item_type: String, champion_xp_level: int) -> Item:
	var item = Item.new()
	item.item_type = item_type
	item.required_level = champion_xp_level
	
	# Randomize item rarity based on weighted chance
	var roll = randf()  # Random float between 0.0 and 1.0	
	if roll <= 0.75:
		item.item_rarity = "Common"
		item.item_level = champion_xp_level  # No bonus for common items
	elif roll <= 0.95:
		item.item_rarity = "Uncommon"
		item.item_level = champion_xp_level + 5
	else:
		item.item_rarity = "Rare"
		item.item_level = champion_xp_level + 10	

	item.item_name = item_type + " of Questing (" + item.item_rarity + ")"
	print("Generated questing gear: ", item.item_name, " | Level: ", item.item_level, " | Rarity: ", item.item_rarity)
	return item
	
# Function to get a random item
func get_random_item():
	return items[randi() % items.size()]


# Function to add an item to the database
func add_item(item: Item):
	items.append(item)

# Initialize with some example items
func _ready():
	# Consumable Items
	var item1 = Item.new("5 ilvl Up", "Increases a Champion's item level by 5", Callable(self, "_use_level_up_item"))
	var item2 = Item.new("500 XP Up", "Increases a Champion's XP points by 500", Callable(self, "_use_xp_up_item"))
	
	# Equipment Items
	var helmet = Item.new()  # Empty constructor
	helmet._init_equipment("Warrior Helmet", "Helmet", 30, "rare", Callable(self, "equip_item_to_champion"))
	
	var neck = Item.new()
	neck._init_equipment("Dragontooth Necklace", "Neck", 20, "rare", Callable(self, "equip_item_to_champion"))

	var shoulders = Item.new()
	shoulders._init_equipment("True-aim Shoulderpads", "Shoulders", 55, "epic", Callable(self, "equip_item_to_champion"))

	var cloak = Item.new()
	cloak._init_equipment("Cloak of Defense", "Cloak", 15, "uncommon", Callable(self, "equip_item_to_champion"))

	var chest = Item.new()
	chest._init_equipment("Emperors' Chainmail", "Chest", 50, "epic", Callable(self, "equip_item_to_champion"))

	var armguards = Item.new()
	armguards._init_equipment("Hunters' Armguards", "Armguards", 30, "rare", Callable(self, "equip_item_to_champion"))

	var gloves = Item.new()
	gloves._init_equipment("Dog Handlers Gloves", "Gloves", 10, "uncommon", Callable(self, "equip_item_to_champion"))

	var belt = Item.new()
	belt._init_equipment("Belt of Might", "Belt", 30, "rare", Callable(self, "equip_item_to_champion"))

	var legs = Item.new()
	legs._init_equipment("Dusk leggings", "Legs", 20, "uncommon", Callable(self, "equip_item_to_champion"))

	var boots = Item.new()
	boots._init_equipment("Striders' Boots", "Legs", 40, "rare", Callable(self, "equip_item_to_champion"))

	var ring = Item.new()
	ring._init_equipment("Ring of Glory", "Ring", 30, "rare", Callable(self, "equip_item_to_champion"))
	
	var trinket = Item.new()
	trinket._init_equipment("Badge of Honour", "Trinket", 60, "epic", Callable(self, "equip_item_to_champion"))
	
	var mainhand = Item.new()
	mainhand._init_equipment("Fireblade Sword", "MainHand", 40, "epic", Callable(self, "equip_item_to_champion"))

	var offhand = Item.new()
	offhand._init_equipment("Sepultural Sceptre", "OffHand", 30, "epic", Callable(self, "equip_item_to_champion"))

	# Add to item database
	add_item(helmet)	
	add_item(neck)
	add_item(shoulders)
	add_item(cloak)
	add_item(chest)
	add_item(armguards)
	add_item(gloves)
	add_item(belt)
	add_item(legs)
	add_item(boots)
	add_item(ring)
	add_item(trinket)
	add_item(mainhand)
	add_item(offhand)
	add_item(item1)
	add_item(item2)

	
	# Print to verify
	for item in items:
		print(item.item_name, " - ", item.item_type, " - ilvl: ", item.item_level, " - Rarity: ", item.item_rarity)

func equip_item_to_champion(champion, item: Item):
	
	# Special handling for rings and trinkets
	if item.item_type == "Ring":
		if champion.equipment_slots["Ring1"] == null:
			champion.equipment_slots["Ring1"] = item
			print(item.item_name, " equipped to Ring 1")
		elif champion.equipment_slots["Ring2"] == null:
			champion.equipment_slots["Ring2"] = item
			print(item.item_name, " equipped to Ring 2")
		else:
			print("Both ring slots occupied. Replacing Ring 1")
			champion.equipment_slots["Ring1"] = item  # Replace Ring 1 by default
	
	elif item.item_type == "Trinket":
		if champion.equipment_slots["Trinket1"] == null:
			champion.equipment_slots["Trinket1"] = item
			print(item.item_name, " equipped to Trinket 1")
		elif champion.equipment_slots["Trinket2"] == null:
			champion.equipment_slots["Trinket2"] = item
			print(item.item_name, " equipped to Trinket 2")
		else:
			print("Both trinket slots occupied. Replacing Trinket 1")
			champion.equipment_slots["Trinket1"] = item

	
	if item.item_type in champion.equipment_slots:
		# Check level requirements
		if item.required_level <= champion.champion_xp_level:
			champion.equip_item(item)
			print(item.item_name, " equipped to ", item.item_type, " on champion: ", champion.champion_name)
		else:
			print("Champion level too low to equip ", item.item_name)
	else:
		print("Invalid slot for ", item.item_type)

func _use_level_up_item(target):
	target.champion_item_level += 5
	print(target.champion_name, " item level increased by 5")

func _use_xp_up_item(target):
	GlobalData.add_xp_to_champion(target, 500)
	#target.champion_xp += 500
	print(target.champion_name, " XP increased by 500. New level: ", str(target.champion_xp_level))


# Generate an equipment item from rarity + monster level.
# - required_level = monster_level ± 2 (min 1)
# - item_level = calculate_item_level(rarity, required_level) via your Item class
# - random equipment slot from EQUIPMENT_SLOTS
func get_random_item_by_rarity(rarity: String, monster_level: int) -> Item:
	var rarity_lc := _normalize_rarity(rarity)
	var req_level := _roll_item_required_level(monster_level)
	var item_type := _random_item_type()

	# Build equipment item using your _init_equipment path
	var item := Item.new()
	item._init_equipment(
		_generate_item_name(item_type, rarity_lc, req_level),
		item_type,
		req_level,
		rarity_lc,
		Callable(self, "equip_item_to_champion")
	)
	# Ensure rarity string is consistent
	item.item_rarity = rarity_lc
	# Optional: tweak description
	item.item_description = "%s %s. Req %d. ilvl %d." % [
		_display_rarity(rarity_lc),
		item.item_type,
		item.required_level,
		item.item_level
	]
	return item
