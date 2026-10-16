extends Control

# Reference to the RichTextLabels
@onready var system_chat_label = $SystemChatPanel/ScrollContainer/VBoxContainer/SystemChat
@onready var member_chat_label = $MemberChatPanel/ScrollContainer/VBoxContainer/MemberChat

# Called when the node enters the scene tree
func _ready():
	update_chats()
	# Set a timer to update the chats every second
	var timer = Timer.new()
	timer.set_wait_time(1.0)
	timer.set_one_shot(false)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()

# Update the chats periodically
func _on_timer_timeout():
	update_chats()

# Function to update the chat messages
func update_chats():
	system_chat_label.clear()
	system_chat_label.push_color(Color(0, 1, 0))  # Set text color to green
	for message in ChatManager.get_system_chat():
		system_chat_label.add_text(message + "\n")
	system_chat_label.pop()  # Reset text color
	system_chat_label.scroll_to_line(system_chat_label.get_line_count())

	member_chat_label.clear()
	member_chat_label.push_color(Color(0, 1, 0))  # Set text color to green
	for message in ChatManager.get_member_chat():
		member_chat_label.add_text(message + "\n")
	member_chat_label.pop()  # Reset text color
	member_chat_label.scroll_to_line(member_chat_label.get_line_count())

func _on_generate_system_message_button_pressed():
	ChatManager.add_system_message("Test system message")
	print("Test system message")
	update_chats()


func _on_generate_member_message_button_pressed():
	ChatManager.add_member_message("Test member message")
	print("Test member message")
	update_chats()
