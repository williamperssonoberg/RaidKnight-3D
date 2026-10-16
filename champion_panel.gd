extends Control

var champion: Champion  # Champion reference

# Variables for dragging
var dragging = false
var drag_offset = Vector2.ZERO

@onready var equipment_grid = $EquipmentGrid
@onready var stats_container = $StatsContainer
@onready var trais_container = $TraitsContainer
@onready var close_button = $CloseChampionPanelButton
@onready var ChampionNameLabel = $TitleBar/ChampionNameLabel

func _ready():
	add_to_group("champion_panel")
	pass

func _on_TitleBar_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			dragging = true
			drag_offset = event.global_position - position
		elif not event.pressed:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = event.global_position - drag_offset

#func _gui_input(event):
#	if event is InputEventMouseButton:
#		if event.button_index == MOUSE_BUTTON_LEFT:
			# Restrict dragging to the TitleBar
#			if event.pressed: #and $TitleBar.get_rect().has_point($TitleBar.get_local_mouse_position()):
#				dragging = true
#				drag_offset = event.global_position - position
#			else:
#				dragging = false
#	elif event is InputEventMouseMotion and dragging:
		# Update panel position while dragging
#		position = event.global_position - drag_offset
#	elif event is InputEventMouseButton and not event.pressed:
#		dragging = false

func _create_debug_border():
	var box = StyleBoxFlat.new()
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.border_color = Color.RED
	box.bg_color = Color(0.1, 0.1, 0.1, 0.5)  # Semi-transparent
	return box
	
# Open and populate with champion data
func open(champ: Champion):
	champion = champ
	populate_panel()
	visible = true

# Populate equipment slots and stats
func populate_panel():
	if not champion:
		return
	
	# Clear old stats
	for child in stats_container.get_children():
		child.queue_free()
	for child in trais_container.get_children():
		child.queue_free()	

	ChampionNameLabel.text = champion.champion_name + " Lvl " + str(champion.champion_xp_level) + " " + champion.champion_specialization + " " + champion.champion_class
	# --- Populate Stats and Traits---
	var stats = {

		"Defense": str(champion.champion_defense_rating),
		"Offense": str(champion.champion_offense_rating),
		"Endurance": str(champion.champion_endurance_rating),
		"Reflexes": str(champion.champion_reflexes_rating),
		"Teamwork": str(champion.champion_teamwork_rating),
		"Focus": str(champion.champion_focus_rating),
		"Morale": str(champion.champion_morale)
	}
	
	var traits = {
		#"Champion Name": champion.champion_name,
		#"XP Level": str(champion.champion_xp_level),
		"Item Level": str(champion.champion_item_level),
		"Race": champion.champion_race,
		"Class": champion.champion_class,
		"Spec": champion.champion_specialization,
		"Profession": champion.profession_skill,
		"Skillfull": champion.skillful_skill,
		"Skill": str(champion.champion_skill)
	}

	# Create and add labels for stats
	for stat_name in stats.keys():
		stats_container.add_child(_create_stat_label(stat_name, stats[stat_name]))
	
	for trait_name in traits.keys():
		trais_container.add_child(_create_stat_label(trait_name, traits[trait_name]))	

	# --- Populate Equipment Slots ---
	for slot_name in champion.equipment_slots:
		if equipment_grid.has_node(slot_name):
			var slot_panel = equipment_grid.get_node(slot_name)
			var equipped_item = champion.equipment_slots[slot_name]
			
			if equipped_item:
				slot_panel.modulate = Color(1, 1, 1)  # Full color for equipped
				slot_panel.tooltip_text = equipped_item.item_name + "\nLevel: " + str(equipped_item.item_level)
				slot_panel.get_child(0).text = slot_name + " " + str(equipped_item.item_level)  # Display item level
			else:
				slot_panel.modulate = Color(0.5, 0.5, 0.5)  # Dim for empty
				slot_panel.tooltip_text = slot_name + " Empty"
				slot_panel.get_child(0).text = slot_name + " Empty"

# Helper to create stat label
func _create_stat_label(label_text: String, value: String) -> Label:
	var label = Label.new()
	label.text = label_text + ": " + value
	return label

#func _on_close_pressed():
#	visible = false



func _on_close_panel_button_pressed():
	print("Close button pressed!")
	hide()


#func _on_button_pressed():
#	print("Close button pressed!")
#	hide()



func _on_close_champion_panel_button_pressed():
	hide()
	print("Close champion panel button pressed!")
