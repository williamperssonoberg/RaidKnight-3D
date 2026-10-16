extends Node

# Store the entire champion object
var selected_champion = null

func set_selected_champion(champion):
	selected_champion = champion  # Store the full object reference
	print("Champion object stored in GameManager: ", selected_champion)


var selected_party = []  # Store multiple champions
var formation_positions = []  # Store positions in the 5x5 grid

func set_selected_party(party_list, positions_list):

	if party_list == null:
		print("Warning: Party list is empty, please add party members.")
		return
	if positions_list == null:
		print("Warning: Positions list is empty, please add party members.")
		return	
	# Ensure C3 is assigned to the first champion
	if positions_list[0] != "slot_C3":
		print("Warning: First champion must be in slot_C3. Assigning automatically.")
		positions_list[0] = "slot_C3"	
	
	selected_party = party_list.duplicate(true)  # Deep copy champion data
	formation_positions = positions_list.duplicate(true)  # Deep copy positions

	print("Party Data Stored:", selected_party)
	print("Formation Positions:", formation_positions)



var dungeon_parameters = {}

func set_dungeon_parameters(params: Dictionary):
	dungeon_parameters = params.duplicate(true)  # Deep copy to prevent overwrites
	print("Dungeon parameters stored:", dungeon_parameters)
