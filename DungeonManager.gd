extends Node


var active_raids = {}  # Dictionary to store multiple ongoing raids
var active_dungeons = {}  # Dictionary to store multiple ongoing dungeons
var is_raid_active = false  # This might now need to be a check per raid
var is_dungeon_active = false
# Reference to GlobalData singleton
#var global_data_node
var chat_manager_node
#var dungeon_play_node: Node2D
# Function to set the reference to GlobalData
#func set_global_data_node(node):
#	global_data_node = node

func _ready():
	#print("Dungeon Manager ready!")
	#global_data_node = get_node("/root/GlobalData")
	#if global_data_node == null:
		#print("Dungeon Manager can't access global data!")
	#if global_data_node != null:
		#print("Dungeon Manager can access Global Data!")	
		

	chat_manager_node = get_node("/root/ChatManager")


func start_dungeon(dungeon_name, dungeon_data, dungeon_party_members):
	print("Current dungeon_timers before starting dungeon: ", GlobalData.dungeon_timers)
	is_dungeon_active = true
	
	# Initialize active_raids
	if not active_dungeons.has(dungeon_name):
		active_dungeons[dungeon_name] = {
			"data": dungeon_data,
			"party_members": dungeon_party_members,
			"position": dungeon_data["party_position"],
			"morale": dungeon_data["dungeon_morale"]
		}
		print("DungeonManager: Active dungeons updated with ", dungeon_name, ":", active_dungeons)
	else:
		print("DungeonManager: Dungeon", dungeon_name, "already active.")		
	# Ensure raid_timers are linked correctly
	if not GlobalData.dungeon_timers.has(dungeon_name + "_party"):
		print("Error: dungeon_timers missing for", dungeon_name + "_party")
	else:
		print("DungeonManager: Dungeon timers for ", dungeon_name + "_party", GlobalData.dungeon_timers[dungeon_name + "_party"])

	print("Dungeon Manager - Started dungeon: " + dungeon_data["dungeon_name"])

func start_raid(raid_name, raid_data, raid_party_members):
	print("Current raid_timers before starting raid: ", GlobalData.raid_timers)
	is_raid_active = true
	
	# Initialize active_raids
	if not active_raids.has(raid_name):
		active_raids[raid_name] = {
			"name": raid_name,
			"data": raid_data,
			"party_members": raid_party_members,
			"position": raid_data["party_position"],
			"morale": raid_data["raid_morale"]
		}
		print("DungeonManager: Active raids updated with ", raid_name, ":", active_raids[raid_name], " and members: ", active_raids[raid_name]["party_members"])
	else:
		print("DungeonManager: Raid", raid_name, "already active.")		
	# Ensure raid_timers are linked correctly
	if not GlobalData.raid_timers.has(raid_name + "_party"):
		print("Error: raid_timers missing for", raid_name + "_party")
	else:
		print("DungeonManager: Raid timers for ", raid_name + "_party", GlobalData.raid_timers[raid_name + "_party"])

	print("Dungeon Manager - Started raid: " + raid_data["name"])
	ChatManager.add_system_message("Started raid: %s" % raid_name)

func move_raid_party_to_previous_pos(raid_name):
	if not active_raids.has(raid_name):
		print("Raid not active: " + raid_name)
		return
		
	var raid = active_raids[raid_name]
	var previous_positions = raid["previous_positions"]
	
	if previous_positions.size() > 0:
		var last_position = previous_positions[-1]  # Get the last element from the list
		raid["position"] = last_position
		previous_positions.pop_back()  # Remove the last entry after moving
		print("Party moved to previous position: ", last_position)
		move_raid_party(raid_name)
	else:
		print("No previous positions to revert to.")
	
	
	
func move_dungeon_party(dungeon_name):
	if not active_dungeons.has(dungeon_name):
		print("Dungeon not active: " + dungeon_name)
		return
	
	var dungeon = active_dungeons[dungeon_name]
	var grid = dungeon["data"]["grid"]
	var position = dungeon["position"]
	var grid_height = dungeon["data"]["grid_height"]
	var grid_width = dungeon["data"]["grid_width"]

	if not dungeon.has("previous_positions"):
		dungeon["previous_positions"] = []  # Initialize movement history if not present

	var previous_positions = dungeon["previous_positions"]

	print("Current grid: ", grid)
	print("Current party position: ", position)
	
	
	if grid.size() == 0 or grid[0].size() == 0:
		print("Error: Grid is empty or not properly initialized")
		is_dungeon_active = false
		return

	# Check if the party is at the final boss room
	if grid[position.y][position.x] == GlobalData.SquareType.FINAL_BOSS_ROOM:
		print("Dungeon completed: " + dungeon_name)
		is_dungeon_active = false
		GlobalData.global_timer.stop()
		return

	# Directions to check (East, West, North, South)
	var possible_moves = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1), Vector2(0, 1)]
	var next_pos = null
	
	for move in possible_moves:
		var new_pos = position + move
		# Check boundaries
		if new_pos.x >= 0 and new_pos.x < grid_width and new_pos.y >= 0 and new_pos.y < grid_height:
			
# Ensure it's a valid tile and hasn't been visited
			if grid[new_pos.y][new_pos.x] in [GlobalData.SquareType.WALKWAY, GlobalData.SquareType.BOSS_ROOM, GlobalData.SquareType.FINAL_BOSS_ROOM]:
				if new_pos not in previous_positions:
					next_pos = new_pos
					break  # Stop at the first unvisited valid position
				
	if next_pos == null:
		print("Error: No valid moves available for party at position: ", position)
		return
		
		# Handle the tile the party is moving to
	if grid[next_pos.y][next_pos.x] == GlobalData.SquareType.BOSS_ROOM:
		encounter_boss(dungeon_name, next_pos)
	elif grid[next_pos.y][next_pos.x] == GlobalData.SquareType.FINAL_BOSS_ROOM:
		print("Party reached the final boss room!")	

	# Update position and save history
	previous_positions.append(position)
	
	dungeon["position"] = next_pos
	print("Party moved to position: ", next_pos)	
	
func move_raid_party(raid_name):
	var party_name = raid_name
	if not active_raids.has(raid_name):
		print("Raid not active: " + raid_name)
		return
	
	var raid = active_raids[raid_name]
	var party_members = raid["party_members"]
	var grid = raid["data"]["grid"]
	var position = raid["position"]
	var grid_height = raid["data"]["grid_height"]
	var grid_width = raid["data"]["grid_width"]
	
	if not raid.has("previous_positions"):
		raid["previous_positions"] = []  # Initialize movement history if not present

	var previous_positions = raid["previous_positions"]
	print("Current party members: ", party_members)
	print("Current grid: ", grid)
	print("Current party position: ", position)
	
	
	if grid.size() == 0 or grid[0].size() == 0:
		print("Error: Grid is empty or not properly initialized")
		is_raid_active = false
		return

	# Check if the party is at the final boss room
	if grid[position.y][position.x] == GlobalData.SquareType.FINAL_BOSS_ROOM:
		print("Raid completed: " + raid_name)
		is_raid_active = false
		GlobalData.global_timer.stop()
		return

		# Determine the next position
	var possible_moves = [Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]  # North, West, East
	var next_pos = null
	for move in possible_moves:
		var new_pos = position + move
		if new_pos.x >= 0 and new_pos.x < grid_width and new_pos.y >= 0 and new_pos.y < grid_height:
			if grid[new_pos.y][new_pos.x] in [GlobalData.SquareType.WALKWAY, GlobalData.SquareType.BOSS_ROOM, GlobalData.SquareType.FINAL_BOSS_ROOM]:
				if new_pos not in previous_positions:
					next_pos = new_pos
					break  # Stop at the first unvisited valid position
				
				
	if next_pos == null:
		print("Error: No valid moves available for party at position: ", position)
		return
		
		# Handle the tile the party is moving to
	if grid[next_pos.y][next_pos.x] == GlobalData.SquareType.BOSS_ROOM:
		encounter_boss(raid_name, next_pos)
	elif grid[next_pos.y][next_pos.x] == GlobalData.SquareType.FINAL_BOSS_ROOM:
		print("Party reached the final boss room!")	
		
	# Update position and save history
	previous_positions.append(position)
		
	raid["position"] = next_pos
	print("Party moved to position: ", next_pos)	

	
func encounter_boss(raid_name, party_position):
	if not active_raids.has(raid_name):
		print("Raid not active: " + raid_name)
		return
	
	var raid = active_raids[raid_name]
	var grid = raid["data"]["grid"]
	#var boss_index = grid.flatten().index(party_position)  # Find the index of the boss room in a flattened grid
	var boss_counter = raid["data"]["boss_counter"]
	var boss_powers = raid["data"]["boss_powers"] #[boss_index]
	var raid_power = calculate_raid_power(raid_name)
	
	# Ensure counter doesn't exceed the number of bosses
	if boss_counter >= boss_powers.size():
		print("Error: No more bosses to encounter in this raid.")
		return
		
	# Fetch the current boss power
	var current_boss_power = boss_powers[boss_counter]
	raid["data"]["boss_counter"] += 1  # Increment the counter for the next boss	
		
	print("Encountered boss with power:", current_boss_power)
	# Continue with boss fight logic	
	
	if raid_power >= current_boss_power:
		print("Boss defeated in raid: ", raid_name, "with raid power: ", raid_power, " against boss power: ", current_boss_power)
		ChatManager.add_system_message("Boss defeated in raid: %s with raid power: %d against boss power: %d" % [raid_name, raid_power, current_boss_power])
	
		# Auto-generate epic loot
		var raid_data = raid["data"]
		var random_slot = ItemDatabase.EQUIPMENT_SLOTS[randi() % ItemDatabase.EQUIPMENT_SLOTS.size()]
		var generated_item = ItemDatabase.generate_epic_item(random_slot, raid_data["average_level_required"])

		# Shuffle party members for random item distribution
		var shuffled_party = raid["party_members"].duplicate()
		shuffled_party.shuffle()
		# Equip item to the champion who needs it
		var item_equipped = false
		for champion in shuffled_party:
			if champion.try_equip_item(generated_item):
				ChatManager.add_system_message("%s equipped %s (iLvl %d)" % [champion.champion_name, generated_item.item_name, generated_item.item_level])
				item_equipped = true
				break
		
		if not item_equipped:
			ChatManager.add_system_message("No champion needed the item: %s" % generated_item.item_name)
			GlobalData.add_item_to_global_inventory(generated_item) 
	
		raid["morale"] = min(raid["morale"] + 10, 100)
		
	elif raid_power >= current_boss_power * 0.95:  # Within 95% of boss power
		print("Close call! But boss fight failed in raid: " + raid_name, "with raid power: ", raid_power, " against boss power: ", current_boss_power)
		ChatManager.add_system_message("Close call! But boss fight failed in raid: %s with raid power: %d against boss power: %d" % [raid_name, raid_power, current_boss_power])
		raid["morale"] = min(raid["morale"] + 1, 100)
		print("Retrying the boss fight in raid: " + raid_name)	
		move_raid_party_to_previous_pos(raid_name)
	else:
		print("Boss overwhelmed the raid: ", raid_name, " with boss power: ", current_boss_power, " against raid power: ", raid_power)
		ChatManager.add_system_message("Boss overwhelmed the raid: %s with boss power: %d against raid power: %d" % [raid_name, current_boss_power, raid_power])
		raid["morale"] -= 10
		if raid["morale"] > 0:
			print("Retrying the boss fight in raid: " + raid_name)
			move_raid_party_to_previous_pos(raid_name)
			# Logic for retrying could be added here
		else:
			print("Raid morale too low to continue. Raid failed: " + raid_name)
			complete_raid(raid_name)  # Mark the raid as failed and clean up

func complete_raid(raid_name):
	print("Completing raid: " + raid_name)
	
	if active_raids.has(raid_name):
		#var raid = active_raids[raid_name]
		# Additional logic for rewards or failure penalties
		
		# Remove from active raids
		active_raids.erase(raid_name)
		
		# Optionally stop the timer if no more raids are active
		if active_raids.size() == 0:
			is_raid_active = false
			GlobalData.global_timer.stop()
			print("All raids completed. Stopping timer.")

func calculate_raid_power(raid_name):
	if not active_raids.has(raid_name):
		print("Raid not active: ", raid_name)
		return 0
	
	var raid = active_raids[raid_name]
	var combined_power = 0
	var party_members = active_raids[raid_name]["party_members"]
	print("Calculating raid power for raid: ", raid_name)
	print("Raid contains raid members of raid: ", raid, " members: ", party_members)
	for champion in party_members:
		# Calculate base champion power
		print("Calculating power for champion: ", champion.champion_name)
		var base_power = champion.calculate_champion_power()
		var adjusted_power = base_power
		
		# Apply skillful skill bonuses
		if champion.skillful_skill: 
			match champion.skillful_skill:
				"Skillful_Healer":
					if champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
						adjusted_power *= 1.05

				"Skillful_Tank":
					if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
						adjusted_power *= 1.05

				"Skillful_Melee_DPS":
					if champion.champion_specialization in ["Berserker", "Stalker", "Wind"]:
						adjusted_power *= 1.05

				"Skillful_Ranged_DPS":
					if champion.champion_specialization in ["Voodoo", "Fire", "Necromancer"]:
						adjusted_power *= 1.05


		# Handle null cases to ensure no errors
		if adjusted_power == null:
			adjusted_power = base_power

		# Apply rarity-based randomness
		var rarity_multiplier = get_rarity_multiplier(champion.champion_rarity)
		adjusted_power *= rarity_multiplier

		# Debugging print
		print(champion.champion_name, " power adjusted to ", adjusted_power, " (Rarity multiplier: ", rarity_multiplier, ")")
		
		# Add to total power
		combined_power += adjusted_power
	
	return combined_power

func get_rarity_multiplier(rarity: String) -> float:
	match rarity:
		"Common":
			return randf_range(0.4, 1.0)
		"Uncommon":
			return randf_range(0.6, 1.0)
		"Rare":
			return randf_range(0.75, 1.0)
		"Epic":
			return randf_range(0.85, 1.05)
		"Legendary":
			return randf_range(0.95, 1.1)
		_:
			return 1.0  # Default to normal power if rarity isn't recognized

func check_morale_and_other_logic():
	# Add other logic here, such as checking raid morale and other status updates
	pass

func _on_dungeon_timeout(party_id):
	var combined_power = 0
	
	# Ensure dictionaries are accessed correctly
	if not GlobalData.active_dungeon_parties.has(party_id):
		print("Error: Party ID", party_id, "not found in active_dungeon_parties")
		return
	if not GlobalData.party_timers.has(party_id):
		print("Error: Party ID", party_id, "not found in party_timers")
		return
	
	# Re-verify presence just before access
	print("Re-verifying presence in active_dungeon_parties:", GlobalData.active_dungeon_parties)
	print("Re-verifying presence in party_timers:", GlobalData.party_timers)

	if GlobalData.active_dungeon_parties.has(party_id):
		print("Accessing Party Data:", GlobalData.active_dungeon_parties[party_id])
	else:
		print("Party ID", party_id, "is missing in active_dungeon_parties after initial check")
		return
			
	var party = GlobalData.active_dungeon_parties[party_id]
	print("Retrieved party data successfully.")
	
	var dungeon_power = GlobalData.party_timers[party_id]["dungeon_power"]
	var dungeon_xp_reward = GlobalData.party_timers[party_id]["dungeon_xp_reward"]
	var dungeon_copper_reward = GlobalData.party_timers[party_id]["dungeon_copper_reward"]
	var dungeon_ilvl_reward = GlobalData.party_timers[party_id]["dungeon_ilvl_reward"]
	
	for champion in party:
		champion.calculate_champion_power()
		var base_power = champion.champion_power
		var adjusted_power = base_power	
		
		# Check if the champion has a skillful skill and adjust power accordingly
		if champion.skillful_skill:
			match champion.skillful_skill:
				"Skillful_Healer":
					if champion.champion_specialization in ["Lightbringer", "Divine", "Water"]:
						adjusted_power *= 1.05
				"Skillful_Tank":
					if champion.champion_specialization in ["Defender", "Soldier", "Earth"]:
						adjusted_power *= 1.05
				"Skillful_Melee_DPS":
					if champion.champion_specialization in ["Berserker", "Stalker", "Wind"]:
						adjusted_power *= 1.05
				"Skillful_Ranged_DPS":
					if champion.champion_specialization in ["Voodoo", "Fire", "Scholar"]:
						adjusted_power *= 1.05
				"None":
					pass
		
		if adjusted_power == null:
			adjusted_power = base_power

		# Add the adjusted power to the combined power
		combined_power += adjusted_power
	
	var success_chance = float(combined_power) / dungeon_power
	if randi() % 100 < success_chance * 100:
		print("Dungeon successful for party: ", party_id)
		
		# Add XP reward to each champion in the party
		for champion in party:
			GlobalData.add_xp_to_champion(champion, dungeon_xp_reward)
			print(champion.champion_name, " received ", dungeon_xp_reward, " XP")
			champion.champion_morale += 20

		# Add copper reward to the guild bank
		GlobalData.add_copper(dungeon_copper_reward)
		print("Added ", dungeon_copper_reward, " copper to the guild bank")
		
		# Assign item level reward to a random champion
		var random_index = randi() % party.size()
		var random_champion = party[random_index]
		random_champion.champion_item_level += dungeon_ilvl_reward
		print(random_champion.champion_name, " received item level reward of ", dungeon_ilvl_reward)
		# Add logic for rewards, XP gain, etc.
		
				# Add system message
		var message = party_id + " complete! Added " + str(dungeon_copper_reward) + " copper to the guild bank."
		ChatManager.add_system_message(message)
		print(message)
		
	else:
		print("Dungeon failed for party:", party_id)
			
		# Add logic for penalties, retries, etc.
	for champion in party:
		champion.champion_morale -= 20
		champion.champion_status = "Idle"
		
	# Clear the dungeon party after completion
	GlobalData.active_dungeon_parties.erase(party_id)
	GlobalData.party_timers.erase(party_id)
	
# Helper function to update the dungeon party list
func update_dungeon_party_list():
	# Add logic to update the dungeon party list UI if necessary
	pass
