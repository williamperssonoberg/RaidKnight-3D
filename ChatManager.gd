extends Node

# Guild system chat messages
var guild_system_chat = []
# Guild member chat messages
var guild_member_chat = []

# Max number of messages to keep in the chat
const MAX_MESSAGES = 100

# Pre-set message databank for random messages
var message_databank = [
	"Hey everyone!",
	"Looking for group!",
	"Anyone up for a dungeon?",
	"GZ on the level up!",
	"Welcome new members!",
	"LOL! L2P!",
	"OMG this is the best game ever!",
	"Anyone SWE?",
	"Hi.",
	"GTG, cya l8r!",
	"GG WP"
]
# Reference to GlobalData
#@onready var global_data = get_node("/root/GlobalData")

func _ready():
	await simulate_random_member_messages()
	print("Chat Manager ready!")
	

# Function to add a message to the guild system chat
func add_system_message(message: String):
	guild_system_chat.append(message)
	if guild_system_chat.size() > MAX_MESSAGES:
		guild_system_chat.pop_front()

# Function to add a message to the guild member chat
func add_member_message(message: String):
	var guild_roster = GlobalData.get_guild_roster()
	if guild_roster.size() > 0:
		var random_champion = guild_roster[randi() % guild_roster.size()]
		var random_member_name = random_champion.champion_name
		message = random_member_name + ": " + message
	guild_member_chat.append(message)
	if guild_member_chat.size() > MAX_MESSAGES:
		guild_member_chat.pop_front()


# Function to get all guild system chat messages
func get_system_chat():
	return guild_system_chat

# Function to get all guild member chat messages
func get_member_chat():
	return guild_member_chat
	
# Function to simulate random member messages

# Asynchronous function to simulate random member messages
func simulate_random_member_messages():
	while true:
		await get_tree().create_timer(randf_range(30, 60)).timeout
		var random_message = message_databank[randi() % message_databank.size()]
		add_member_message(random_message)
		print("Guild Member Chat:", random_message)

# Function to handle adding a new member
func add_guild_member(member_name: String):
	var welcome_message = "Welcome " + member_name + "!"
	add_member_message(welcome_message)
	print("Guild Member Chat:", welcome_message)

# Function to handle leveling up
func guild_member_level_up(member_name: String):
	var level_up_message = "GZ " + member_name + " on the level up!"
	add_member_message(level_up_message)
	print("Guild Member Chat:", level_up_message)
