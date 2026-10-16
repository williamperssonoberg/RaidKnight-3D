# GlobalData.gd

extends Node

#raid stuff
enum SquareType {
	EMPTY,
	WALKWAY,
	BOSS_ROOM,
	FINAL_BOSS_ROOM,
	ENTRANCE
}
var dungeons = {}  # Dictionary to store dungeons
var raids = {}  # Dictionary to store raids
var generated_raids = []  # Global list to store generated raids
var generated_raids_counter = 0  # New counter to track raid names
var preset_raids = []
#var dungeon_play_node

var copper_total = 0  # Assume this is a global variable or part of a singleton/global script
var copper_gained
signal currency_changed

var guild_roster_data = []
var xp_gained


var active_dungeon_parties: Dictionary = {}  
var dungeon_parties: Dictionary = {}
var raid_parties: Dictionary = {}   # Dictionary to store raid parties
var party_timers: Dictionary = {}   # Dictionary to store start times for each party
var raid_timers: Dictionary = {}  # Global dictionary to track active raid timers
var dungeon_timers: Dictionary = {} # Global dictionary to track active dungeon timers
var global_timer = Timer.new()
var dungeon_manager

var instance_id = randi()  # Unique ID for each instance

var raid_play_scene_ref: Node = null  # Reference to the raid_play_scene script

var seconds_counter = 0  # Counter to track seconds

#const Champion = preload("res://champion.gd")

func _ready():
	set_process(true)  # Enable processing so that _process is called
	set_process_input(true)  # Enable processing input
	
	if not get_tree().get_root().has_node("HUD"):
		var hud = load("res://HUD.tscn").instantiate()
		get_tree().get_root().add_child(hud)
		hud.set_name("HUD")	
	
	add_child(global_timer)	
	global_timer.set_wait_time(1.0)
	global_timer.set_one_shot(false)
	global_timer.connect("timeout", Callable(self, "_on_global_timer_timeout"))
	global_timer.start()
	print("Global Timer initialized and started")
	
	initialize_preset_raids()  # Initialize preset raids	
	print("raid_timers initialized:", raid_timers)
	
	print("GlobalData instance initialized. ID:", instance_id)

	dungeon_manager = get_node("/root/DungeonManager")
	if dungeon_manager == null:
		print("Global Data can't access Dungeon Manager!")
		
	if global_timer.is_stopped():
		print("Global timer is not running. Starting it now.")
		global_timer.start()
	else:
		print("Global timer is already running.")
# Function to set guild roster data
func set_guild_roster(guild_roster):
	guild_roster_data = guild_roster
	print("Global Data Guild Roster updated")
	print(guild_roster_data)

# Function to get guild roster data
func get_guild_roster():
	print("Global Data Guild Roster retreived")
	return guild_roster_data
	
# Function to get a champion by name
func get_champion_by_name(name: String):
	for champion in guild_roster_data:
		if champion.champion_name == name:
			return champion
	return null	

func update_hud():
	print("GlobalData Update_hud called!")
	print("Contents of guild_roster_data: ", guild_roster_data)
	#var hud = get_tree().get_root().get_node_or_null("HUD")
	var hud = Hud
	if hud:
		var guild_power = calculate_guild_power()
		#var gold = 0
		#var silver = 0
		#var copper = 0
		#get_currency()
	#	hud.update_currency_hud_label()	
		hud.update_guild_members_hud_label(guild_roster_data.size())
		hud.update_guild_power_hud_label(guild_power)
		
func calculate_guild_power() -> int:
	var total_power = 0
	for champion in guild_roster_data:
		total_power += champion.calculate_champion_power()
	return total_power
	
#-------XP gain functionality-------------------------------------------------------

# Function to calculate the current level based on XP
func calculate_level(xp: int) -> int:
	var level = 0
	for i in range(xp_thresholds.size()):
		if xp < xp_thresholds[i]:
			break
		level += 1
	return level
	
# Function to update champion's XP when they complete activities
func add_xp_to_champion(champion, xp_gained: int):
	champion.champion_xp += xp_gained
	var new_level = calculate_level(champion.champion_xp)
	if new_level > champion.champion_xp_level:
		champion.champion_xp_level = new_level
		print(champion.champion_name, " is now level", new_level)
		ChatManager.add_system_message("Ding! %s is now level %d" % [champion.champion_name, new_level])
		update_hud()

# Define XP thresholds for each level
var xp_thresholds = [
	0, 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500,
	7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700, 19400, 21300,
	23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44100,
	46800, 49600, 52500, 55500, 58600, 61700, 64900, 68200, 71600, 75100,
	78700, 82400, 86100, 90000, 94000, 98100, 102300, 106600, 111000, 115500,
	120100, 124800, 129600, 134500, 139500, 144600, 149800, 155100, 160500, 166000,
	171600, 177300, 183100, 189000, 195000, 201000, 207100, 213300, 219600
]

func _process(delta: float):
	process_champion_xp(delta)

func process_champion_xp(delta: float):

	for champion in guild_roster_data:
		if champion.champion_status == "Solo Questing":
			
			champion.xp_time_accumulator += delta  # Accumulate time
			#print(str(champion.xp_time_accumulator) + " added by " + str(delta))
			
			# Check if one minute has passed
			if champion.xp_time_accumulator >= 60.0:
				xp_gained = 16  # XP gained per minute
				copper_gained = 10   # Copper gained per minute
				champion.add_xp(xp_gained)  # Add XP to the champion
				add_copper(copper_gained)  # Add copper to the total
				print(champion.champion_name + " gained " + str(xp_gained) + " XP")
				print(champion.champion_name + " earned " + str(copper_gained) + " copper")
				var roll = randf()  # Random float between 0.0 and 1.0	
				if roll >= 0.80:
					var random_slot = ItemDatabase.EQUIPMENT_SLOTS[randi() % ItemDatabase.EQUIPMENT_SLOTS.size()]
					var generated_item = ItemDatabase.generate_questing_gear(random_slot, champion.champion_xp_level)
					var item_equipped = false

					if champion.try_equip_item(generated_item):
						ChatManager.add_system_message("%s equipped %s (iLvl %d)" % [champion.champion_name, generated_item.item_name, generated_item.item_level])
						item_equipped = true

		
					if not item_equipped:
						ChatManager.add_system_message("No champion needed the item: %s" % generated_item.item_name)
						GlobalData.add_item_to_global_inventory(generated_item) 
				# Subtract one minute from the time accumulator
				champion.xp_time_accumulator -= 60.0
		



#------- copper-------------------------------------------------------------------

func add_copper(amount: int):
	copper_total += amount
	emit_signal("currency_changed")
	get_currency()
	#update_hud()

func get_currency():
	var gold = copper_total / 10000
	var silver = (copper_total / 100) % 100
	var copper = copper_total % 100
	Hud.update_currency_hud_label(gold, silver, copper)
	return [gold, silver, copper]

#-------------Dungeon parties-----------------------------------------------------

func _on_global_timer_timeout():
	#print("Global Timer Timeout executed")
	
	#print("Global Timer Timeout. Pre-existing raid_timers: ", raid_timers)
	#if raid_timers.size() == 0:
		#print("Global timer error: raid_timers is empty!")
		#return
	
	
	seconds_counter += 1
	var current_time = Time.get_ticks_msec() / 1000

	
	for party_id in party_timers.keys():
		print("Processing party_id:", party_id)
		if typeof(party_timers[party_id]) == TYPE_DICTIONARY:
			print("party_id", party_id, "is a dictionary.")
			var start_time = party_timers[party_id]["start_time"]
			var dungeon_time = party_timers[party_id]["dungeon_time"]
			var elapsed_time = current_time - start_time
			var countdown_time = max(0, (start_time + (dungeon_time * 60)) - current_time)

			party_timers[party_id]["countdown_time"] = countdown_time  # Update the countdown time
			print("Updated countdown_time for party:", party_id, "Countdown time:", countdown_time)

			
			 # Add XP and copper rewards each minute
			if elapsed_time % 60 == 0:  # Check if a minute has passed
				var minute_xp = party_timers[party_id]["minute_xp"]
				var minute_copper = party_timers[party_id]["minute_copper"]
				var party = active_dungeon_parties[party_id]
				
				# Add XP to each champion in the party
				for champion in party:
					add_xp_to_champion(champion, minute_xp)
					print(champion.champion_name, "received", minute_xp, "XP")

				# Add copper to the guild bank
				add_copper(minute_copper)
				print("Added", minute_copper, "copper to the guild bank")



			if countdown_time <= 0:
				if dungeon_manager != null:
					dungeon_manager._on_dungeon_timeout(party_id)

				else:
					print("Error: dungeon_manager instance is not set.")
				
				# Remove the party from active_dungeon_parties and party_timers
				active_dungeon_parties.erase(party_id)
				party_timers.erase(party_id)	
		
		else:
			print("Error: party_id: [", party_id, "] is not a dictionary. Type:", typeof(party_timers[party_id]))
	
		# Check morale every 60 seconds (1 minute)
	if seconds_counter >= 60:
		seconds_counter = 0  # Reset counter
		for champion in guild_roster_data:
			update_champion_morale(champion)
	
	# Iterate over all active raids
	# Iterate over all raid timers
	for raid_party_name in raid_timers.keys():
		if not raid_timers[raid_party_name].has("countdown_time"):
			print("Error: Missing countdown_time for", raid_party_name)
			continue
		var raid_name = raid_party_name.replace("_party", "")	
		print("Current raid party in Dung Man: ", DungeonManager.active_raids[raid_name]["party_members"])
		#ensure_raid_play_scene()
		var raid_data = raid_timers[raid_party_name]
		#var raid_name = raid_timers[raid_party_name]
		# Decrement countdown timer
		var countdown_time = raid_timers[raid_party_name]["countdown_time"]
		# Decrement countdown timer
		if countdown_time > 0:
			countdown_time -= 1
			raid_data["countdown_time"] = countdown_time
			print("Updated countdown_time for", raid_party_name, ":", countdown_time)

		# Calculate move interval if not already done
			if not raid_data.has("move_interval"):
				#var grid = raid_data["grid"]
				var total_moving_tiles = raid_data["total_moving_tiles"]
				raid_data["move_interval"] = max(1, int(raid_data["raid_time"] * 60 / total_moving_tiles))  # Convert raid_time to seconds
				raid_data["move_countdown"] = raid_data["move_interval"]  # Initialize move countdown

		# Decrement move countdown
			raid_data["move_countdown"] -= 1
			if raid_data["move_countdown"] <= 0:
				raid_data["move_countdown"] = raid_data["move_interval"]  # Reset the move countdown

				print("Move interval reached. Moving party for raid: ", raid_name)
				DungeonManager.move_raid_party(raid_name)

		else:
			print("Raid", raid_party_name, "has completed.")
			DungeonManager.complete_raid(raid_party_name.replace("_party", ""))
			if has_node("/root/raid_play_scene"):
				var raid_play_scene = get_node("/root/raid_play_scene")
				raid_play_scene.remove_raid_button(raid_party_name)
			#	raid_play_scene.remove_raid_button(raid_name)  # Optional: remove the button from the UI
		#	print("Completed raid: " + raid_name)
		
		
	for dungeon_party_name in dungeon_timers.keys():
		if not dungeon_timers[dungeon_party_name].has("countdown_time"):
			print("Error: Missing countdown_time for", dungeon_party_name)
			continue
		

		#ensure_raid_play_scene()
		var dungeon_data = dungeon_timers[dungeon_party_name]
		#var raid_name = raid_timers[raid_party_name]
		# Decrement countdown timer
		var countdown_time = dungeon_timers[dungeon_party_name]["countdown_time"]
		# Decrement countdown timer
		if countdown_time > 0:
			countdown_time -= 1
			dungeon_data["countdown_time"] = countdown_time
			print("Updated countdown_time for dungeon party: ", dungeon_party_name, " : ", countdown_time)

		# Calculate move interval if not already done
			if not dungeon_data.has("move_interval"):
				#var grid = raid_data["grid"]
				var total_moving_tiles = dungeon_data["total_moving_tiles"]
				dungeon_data["move_interval"] = max(1, int(dungeon_data["dungeon_time"] * 60 / total_moving_tiles))  # Convert raid_time to seconds
				dungeon_data["move_countdown"] = dungeon_data["move_interval"]  # Initialize move countdown

		# Decrement move countdown
			dungeon_data["move_countdown"] -= 1
			if dungeon_data["move_countdown"] <= 0:
				dungeon_data["move_countdown"] = dungeon_data["move_interval"]  # Reset the move countdown
				var dungeon_name = dungeon_party_name.replace("_party", "")
				print("Move interval reached. Moving party for dungeon: ", dungeon_name)
				DungeonManager.move_dungeon_party(dungeon_name)

		else:
			print("Dungeon", dungeon_party_name, "has completed.")
			DungeonManager.complete_raid(dungeon_party_name.replace("_party", ""))
			if has_node("/root/raid_play_scene"):
				var dungeon_play_scene = get_node("/root/raid_play_scene")
				dungeon_play_scene.remove_dungeon_button(dungeon_party_name)
			#	raid_play_scene.remove_raid_button(raid_name)  # Optional: remove the button from the UI
		#	print("Completed raid: " + raid_name)




func add_dungeon(dungeon_data: Dictionary):
	for dungeon_key in dungeon_data:
		var dungeon_entry = dungeon_data[dungeon_key]  # Access the nested dictionary
		var dungeon_name = dungeon_entry["dungeon_name"]  # Now access dungeon_name inside the entry
		
		# Store by dungeon_name as key
		dungeons[dungeon_name] = dungeon_entry
		print("Added dungeon:", dungeon_name)

func add_raid(raid_data):
	raids[raid_data["name"]] = raid_data
	generated_raids.append(raid_data)  # Add to global list of generated raids

func add_preset_raid(raid_data):
	raids[raid_data["name"]] = raid_data


func remove_raid_from_generated(raid_name):
	print("Called remove_raid_from_generated in Global Data generated raids: ", generated_raids, " on raid: ", raid_name)
	for i in range(generated_raids.size()):
		print("Checking index", i, "with name:", generated_raids[i].name)  # Log current index and raid name
		if generated_raids[i].name == raid_name:
			print("Match found! Removing:", generated_raids[i].name)  # Confirm a match
			generated_raids.remove_at(i)
			print("Updated generated_raids:", generated_raids)  # Log updated array
			break
	
func start_dungeon(dungeon_name):
	print("Attempting to start dungeon:", dungeon_name)
	
	if dungeon_name in dungeons:
		print("Got dungeon from dungeon scene, sending to DungeonManager: ", dungeon_name)
		var dungeon_data = dungeons[dungeon_name]
		#var raid_party = raid_parties[raid_party_name]

		var dungeon_party_name = dungeon_name + "_party"
		if dungeon_party_name in dungeon_parties:
			var dungeon_party_members = dungeon_parties[dungeon_party_name]
			var dungeon_party_power = calculate_raid_party_power(dungeon_party_members)
			# Initialize raid timers here
			if not dungeon_timers.has(dungeon_party_name):
				var dungeon_time = calculate_raid_time(dungeon_data["grid"], dungeon_data["dungeon_power"], dungeon_party_power)  # Use the grid to determine the dungeon time
				var start_time = Time.get_ticks_msec() / 1000  # Current time in seconds
				var grid = dungeon_data["grid"]
				var total_moving_tiles = 0
				for row in grid:
					for cell in row:
						if cell == SquareType.WALKWAY or cell == SquareType.BOSS_ROOM or cell == SquareType.FINAL_BOSS_ROOM or cell == SquareType.ENTRANCE:
							total_moving_tiles += 1
				dungeon_timers[dungeon_party_name] = {
					"start_time": start_time,
					"dungeon_time": dungeon_time,
					"countdown_time": dungeon_time * 60,  # Convert to seconds
					"button": null,  # Placeholder for the button reference
					"total_moving_tiles": total_moving_tiles
				}
				print("Initialized dungeon_timers for:", dungeon_party_name, "with raid time: ", dungeon_time, " minutes")
				print("start_dungeon: Current dungeon_timers:", self.dungeon_timers)
			
			# Pass dungeon data to DungeonManager
			DungeonManager.start_dungeon(dungeon_name, dungeon_data, dungeon_party_members)


		else:
			print("Dungeon party not found:", dungeon_party_name)
	else:
		print("Dungeon not found in Dungeons dictionary:", dungeon_name)
	
func start_raid(raid_name):
	print("Attempting to start raid:", raid_name)
	
	if raid_name in raids:
		print("Got raid from raid scene, sending to DungeonManager: ", raid_name)
		var raid_data = raids[raid_name]
		#var raid_party = raid_parties[raid_party_name]

		var raid_party_name = raid_name + "_party"
		if raid_party_name in raid_parties:
			var raid_party_members = raid_parties[raid_party_name]
			var raid_party_power = calculate_raid_party_power(raid_party_members)
			# Initialize raid timers here
			if not raid_timers.has(raid_party_name):
				var raid_time = calculate_raid_time(raid_data["grid"], raid_data["raid_power"], raid_party_power)  # Use the grid to determine the raid time
				var start_time = Time.get_ticks_msec() / 1000  # Current time in seconds
				var grid = raid_data["grid"]
				var total_moving_tiles = 0
				for row in grid:
					for cell in row:
						if cell == SquareType.WALKWAY or cell == SquareType.BOSS_ROOM or cell == SquareType.FINAL_BOSS_ROOM or cell == SquareType.ENTRANCE:
							total_moving_tiles += 1
				raid_timers[raid_party_name] = {
					"start_time": start_time,
					"raid_time": raid_time,
					"countdown_time": raid_time * 60,  # Convert to seconds
					"button": null,  # Placeholder for the button reference
					"total_moving_tiles": total_moving_tiles
				}
				print("Initialized raid_timers for:", raid_party_name, "with raid time: ", raid_time, " minutes")
				print("start_raid: Current raid_timers:", self.raid_timers)
			
			# Pass raid data to DungeonManager
			DungeonManager.start_raid(raid_name, raid_data, raid_party_members)
			#raids.erase(raid_name)
			#raid_parties.erase(raid_party_name)
		else:
			print("Raid party not found:", raid_party_name)
	else:
		print("Raid not found in raids dictionary:", raid_name)

func add_dungeon_party(dungeon_party_name, dungeon_party, grid):
	if not dungeon_parties.has(dungeon_party_name):
		dungeon_parties[dungeon_party_name] = dungeon_party
		print("func add_dungeon_party: Added dungeon party: ", dungeon_party_name, " with members:", dungeon_party)
	else:
		print("func add_dungeon_party: Dungeon party allready exist for: ", dungeon_party_name, " : ", dungeon_party)

func add_raid_party(raid_party_name, raid_party, grid):
	if not raid_parties.has(raid_party_name):
		raid_parties[raid_party_name] = raid_party
		print("func add_raid_pary: Added raid party: ", raid_party_name, " with members:", raid_party)

#	if not raid_timers.has(raid_party_name):
		#var raid_data = raids[raid_name]
#		var raid_time = calculate_raid_time(raid_data["grid"], raid_data["raid_power"]) # Use the grid to determine the raid time
#		var start_time = Time.get_ticks_msec() / 1000  # Current time in seconds
#		var raid_data = {
#			"start_time": start_time,
#			"raid_time": raid_time,  # Set the calculated raid time in minutes
#			"countdown_time": raid_time * 60,  # Convert to seconds
#			"button": null  # Placeholder for the button reference
#		}
#		raid_timers[raid_party_name] = raid_data
#		print("func add_raid_pary: Initialized raid_timers for: ", raid_party_name, " : ", raid_timers[raid_party_name], " with raid time: ", raid_time, " minutes")
	else:
		print("func add_raid_pary: Raid party allready exist for: ", raid_party_name, " : ", raid_party)
		#print("func add_raid_pary: Raid timers already exist for: ", raid_party_name, " : ", raid_timers)

func get_raid_time(raid_party_name):
	if raid_timers.has(raid_party_name):
		return raid_timers[raid_party_name]["countdown_time"]
	else:
		print("Error: Raid party name not found in raid_timers:", raid_party_name)
		return null
	print("function get_raid_time: Current raid_timers:", self.raid_timers)		

func remove_from_roster(champion):
	guild_roster_data.erase(champion)
	#update_roster_list()  # Update the roster list UI after removal

func update_champion_morale(champion):
	if champion.champion_status == "Idle":
		champion.champion_morale -= 1
		print(champion.champion_name + " lost 1 morale point due to inactivity.")
	else:
		champion.champion_morale = min(champion.champion_morale + 2, 1000)

	if champion.champion_morale <= 100:
		var quit_chance = 1 / float(champion.champion_morale)
		if randi() % 100 < quit_chance * 100:
			print(champion.champion_name + " has quit the guild due to low morale! :( ")
			remove_from_roster(champion)

# Function to add a new party
func add_party(party_id, members, initial_time, dungeon_time, dungeon_xp_reward, dungeon_copper_reward, dungeon_ilvl_reward, dungeon_power, minute_xp, minute_copper):
	active_dungeon_parties[party_id] = members
	var start_time = Time.get_ticks_msec() / 1000
	party_timers[party_id] = {
		"start_time": start_time,
		"countdown_time": initial_time,
		"dungeon_time": dungeon_time,
		"dungeon_power": dungeon_power,
		"dungeon_xp_reward": dungeon_xp_reward,
		"dungeon_copper_reward": dungeon_copper_reward,
		"dungeon_ilvl_reward": dungeon_ilvl_reward,
		"minute_xp": minute_xp,
		"minute_copper": minute_copper
	}
	print("Added party:", party_id, "with start_time:", start_time, "and initial_time:", initial_time, "and dungeon_time:", dungeon_time)
	
func get_party(party_id):
	return active_dungeon_parties.get(party_id, [])
	

func get_party_time(party_id):
	if party_id in dungeon_timers and typeof(dungeon_timers[party_id]) == TYPE_DICTIONARY:
		return dungeon_timers[party_id].get("countdown_time", 0)
	print("Error: party_id ", party_id, " not found or not a dictionary in party_timers. Type:", typeof(party_timers.get(party_id)))
	return 0


	
# Global list to store inventory items
var global_inventory_items = []

# Function to add an item to the global inventory
func add_item_to_global_inventory(item):
	global_inventory_items.append(item)
	print("Added ", item.item_name, " to Guild Inventory")

# Function to remove an item from the global inventory
func remove_item_from_global_inventory(item):
	for i in range(global_inventory_items.size()):
		if global_inventory_items[i] == item:
			global_inventory_items.remove_at(i)
			return


func calculate_raid_time(grid, raid_power, raid_party_power):
	# Calculate the base time in minutes based on the grid
	var time_in_minutes = 0
	for row in grid:
		for cell in row:
			if cell == SquareType.WALKWAY or cell == SquareType.BOSS_ROOM or cell == SquareType.FINAL_BOSS_ROOM or cell == SquareType.ENTRANCE:
				time_in_minutes += 1
	#var raid_power = raid_power  # Fetch the raid power from the raid data
	#var raid_party_power = calculate_raid_party_power(raid_name) 
	# Ensure we don't divide by zero
	if raid_party_power == 0:
		print("Error: Raid party power cannot be zero.")
		return time_in_minutes
 # Assuming you have this function
	# Adjust time based on power comparison
	var adjusted_time = (raid_power / raid_party_power) * time_in_minutes		

	print("Base raid time in minutes: " + str(time_in_minutes))
	print("Adjusted raid time in minutes: " + str(adjusted_time))
	return int(adjusted_time)

func calculate_raid_party_power(raid_party_members):
	var total_power = 0
	for champion in raid_party_members:
		print("Champion object: ", champion, " has Champion XP level: ", champion.champion_xp_level, " and Champion item level: ", champion.champion_item_level, " and Champion skill: ", champion.champion_skill)
		if champion is Champion:
			var champ = champion as Champion
			if champ.has_method("calculate_champion_power"):
				var power = champ.calculate_champion_power()
				if power == null:  # Handle Nil cases
					print("Warning: calculate_champion_power returned Nil for: ", champ)
					power = 0
				total_power += power
				print("Champion power: ", power)
			else:
				print("Warning: Champion missing calculate_champion_power method.")
		else:
			print("Error: Object is not a Champion: ", champion)
	print("Total party power: ", total_power)
	return total_power


# Function to retrieve raid data by name
func get_dungeon_data(dungeon_name: String) -> Dictionary:
	if dungeons.has(dungeon_name):
		print("Found ", dungeon_name, " in dungeon_data.")
		return dungeons[dungeon_name]
	
	# If not found, print an error and return an empty dictionary
	print("func get_dungeon_data: Error: Dungeon data for ", dungeon_name, " not found.")
	return {}  # Return an empty dictionary


# Function to retrieve raid data by name
func get_raid_data(raid_name: String) -> Dictionary:
	if raids.has(raid_name):
		return raids[raid_name]
	
	# Search through the generated raids list
	for raid in generated_raids:
		if raid.has("name") and raid["name"] == raid_name:
			return raid
	
	# If not found, print an error and return an empty dictionary
	print("func get_raid_data: Error: Raid data for ", raid_name, "not found.")
	return {}  # Return an empty dictionary


func initialize_preset_raids():
	
	var preset_data = preload("res://preset_dungeons_raids.gd").new()
	preset_raids = preset_data.preset_raids
	
	print("Preset Raids Loaded: ", preset_raids.size())
	
	
	for raid in preset_raids:
		add_preset_raid(raid)
		
func create_preset_raid_grid():
	var grid = []
	for y in range(30):  # Assuming a 20x10 grid
		var row = []
		for x in range(15):
			if y == 0:
				row.append(SquareType.WALKWAY)  # Starting row
			elif y == 19 and x == 5:
				row.append(SquareType.FINAL_BOSS_ROOM)  # Final boss room
			elif y % 5 == 0 and x % 3 == 0:
				row.append(SquareType.BOSS_ROOM)  # Boss rooms
			else:
				row.append(SquareType.EMPTY)  # Empty spaces
		grid.append(row)
	return grid
