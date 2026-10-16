extends Control


@onready var btn_continue: Button = %ContinueButton
@onready var btn_exit: Button = %ExitDungeonButton
@onready var btn_guild: Button = %GuildInventoryButton
@onready var party_list_node = %PartyList            # ItemList OR VBoxContainer
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var item_description = $ItemDescription
@onready var victoryLabel = %VictoryLabel

var selected_champion = null
var selected_item = null

# Function to handle item button pressed
func _on_item_info_message(item):
	selected_item = item
	item_description.text = item.item_description

func item_name_for_display(item) -> String:
	if typeof(item) == TYPE_DICTIONARY:
		return item.get("name", "Item")
	elif item is ItemDatabase.Item:
		return item.item_name if item.item_name != "" else "Item"
	return "Item"

func rarity_color(r: String) -> Color:
	match r.to_lower():
		"legendary":
			return Color(1.0, 0.6, 0.2, 0.28)
		"epic":
			return Color(0.75, 0.45, 1.0, 0.28)
		"rare":
			return Color(0.4, 0.6, 1.0, 0.28)
		_:
			return Color(0.3, 1.0, 0.3, 0.28) # uncommon

func item_rarity_for_display(item) -> String:
	if typeof(item) == TYPE_DICTIONARY:
		return str(item.get("item_rarity", "uncommon")).to_lower()
	elif item is ItemDatabase.Item:
		return str(item.item_rarity).to_lower()
	return "uncommon"



var world: Node = null
var _party_cache: Array = []

func _ready():
	# Wire buttons
	btn_continue.pressed.connect(_on_continue)
	btn_exit.pressed.connect(_on_exit_dungeon)
	btn_guild.pressed.connect(_on_open_guild)
	var world = get_tree().get_first_node_in_group("dungeon_world")
	if world:
		world.connect("item_info_message", Callable(self, "_on_item_info_message"))

func populate_victory(crawler_world: Node) -> void:
	world = crawler_world
	_populate_party()
	_populate_inventory()
	btn_continue.hide()
	btn_guild.show()
	victoryLabel.show()

func populate(crawler_world: Node) -> void:
	world = crawler_world
	_populate_party()
	_populate_inventory()

func _populate_party() -> void:
	# Clear then add
	if party_list_node is ItemList:
		party_list_node.clear()
	else:
		for c in party_list_node.get_children():
			c.queue_free()

	_party_cache.clear()
	var party_list = GameManager.selected_party
	if not party_list:
		return

	for i in range(party_list.size()):
		var champ = party_list[i]
		_party_cache.append(champ)
		if party_list_node is ItemList:
			party_list_node.add_item("%s  (Lv.%d)" % [champ.champion_name, champ.champion_xp_level])
		else:
			var h = HBoxContainer.new()
			var lbl = Label.new()
			lbl.text = "%s  (Lv.%d)" % [champ.champion_name, champ.champion_xp_level]
			var btn = Button.new()
			btn.text = "Inspect"
			btn.pressed.connect(_on_inspect.bind(i))
			h.add_child(lbl)
			h.add_child(btn)
			party_list_node.add_child(h)

func _populate_inventory() -> void:
	# grid: 5 columns; rows = party_size
	inventory_grid.columns = 5
	for c in inventory_grid.get_children():
		c.queue_free()

	if not world:
		return

	var items: Array = world.dungeon_inventory
	var capacity: int = world.dungeon_inventory_capacity

	# build fixed number of slots (capacity)
	for slot_index in range(capacity):
		var slot_container = VBoxContainer.new()
		slot_container.custom_minimum_size = Vector2(80, 120)
		slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_container.alignment = BoxContainer.ALIGNMENT_CENTER		
		
		# --- Main item button (name or empty) ---
		var btn_item = Button.new()
		btn_item.custom_minimum_size = Vector2(70, 70)
		btn_item.text = "Empty"
		btn_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_item.size_flags_vertical = Control.SIZE_EXPAND_FILL

		# ✅ Text wrapping and centering
		btn_item.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn_item.clip_text = false
		btn_item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
#		btn_item.align = HORIZONTAL_ALIGNMENT_CENTER
#		btn_item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		# --- Item background tint by rarity ---
		var item: Variant = items[slot_index] if slot_index < items.size() else null
		if item:
			var rarity := item_rarity_for_display(item)
			btn_item.modulate = rarity_color(rarity)
			btn_item.text = item_name_for_display(item)
			btn_item.pressed.connect(_on_slot_equip.bind(slot_index))
		else:
			btn_item.modulate = Color(0, 0, 0, 0.4)
			btn_item.disabled = true
		
		# --- Buttons underneath (Send / Drop) ---
		var h = HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER

		var btn_send = Button.new()
		btn_send.text = "Send"
		btn_send.custom_minimum_size = Vector2(32, 24)

		var btn_drop = Button.new()
		btn_drop.text = "Drop"
		btn_drop.custom_minimum_size = Vector2(32, 24)

		btn_send.disabled = item == null
		btn_drop.disabled = item == null
		btn_send.pressed.connect(_on_slot_send.bind(slot_index))
		btn_drop.pressed.connect(_on_slot_drop.bind(slot_index))

		h.add_child(btn_send)
		h.add_child(btn_drop)

		# --- Assemble ---
		slot_container.add_child(btn_item)
		slot_container.add_child(h)
		inventory_grid.add_child(slot_container)

# --- Buttons ---
func _on_continue():
	get_tree().paused = false
	hide()

func _on_exit_dungeon():
	# You can add a confirmation dialog
	get_tree().paused = false
	world.dungeon_inventory.clear()
	get_tree().change_scene_to_file("res://dungeons_play_scene.tscn")

	# TODO: call back into world to clean up and exit to city
#	if world and world.has_method("_on_dungeon_complete"):
#		world._on_dungeon_complete()

func _on_open_guild():
	# Open your guild inventory panel (you likely have a scene/panel for this)
	# e.g. emit a signal to world or call a method
	if world and world.has_method("open_guild_inventory"):
		world.open_guild_inventory()

func _on_inspect(index: int):
	var champ = _party_cache[index]
	selected_champion = champ
	# call your champion panel opener in world, pass champ
	if world and world.has_method("open_champion_panel"):
		world.open_champion_panel(champ)

# --- Inventory actions ---
func _on_slot_equip(slot_index: int):
	if selected_champion and world and world.has_method("equip_item_from_dungeon_slot"):
		world.equip_item_from_dungeon_slot(slot_index, selected_champion)
		_populate_inventory()  # refresh
	else:
		return
		
	
func _on_slot_send(slot_index: int):
	if world and world.has_method("send_item_to_guild_from_slot"):
		world.send_item_to_guild_from_slot(slot_index)
		_populate_inventory()

func _on_slot_drop(slot_index: int):
	if world and world.has_method("drop_item_from_slot"):
		world.drop_item_from_slot(slot_index)
		_populate_inventory()
