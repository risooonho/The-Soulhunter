extends Control

const default_chats = ["System", "Global", "Local", "Whisper"]
const chat_colors = [Color(0.8, 0.8, 0.8), Color(1, 1, 0.4), Color(0.3, 0.5, 1), Color(0.7, 0.2, 1)]

onready var font = load("res://Resources/UI/DefaultFont.tres")

var mode = Data.CHATS.GLOBAL
var whisper = ""
var last_whisper = ""

onready var history = $Container/History
onready var input = $Container/Input/Text
onready var chat_mode = $Container/Input/Chat

const PLACEHOLDER = "T to chat, /g global, /l local, /w NAME whisper, /r reply"

func _ready():
	Com.controls.connect("key_press", self, "on_key_press")
	Network.connect("chat_message", self, "on_message_get")
	input.placeholder_text = PLACEHOLDER

func on_message_get(type, from, message):
	add_message(from, message, type)
	
	if type == Data.CHATS.WHISPER:
		last_whisper = from

func add_message(author, message, type = mode, add_whisper = false):
	history.push_color("#" + chat_colors[type].to_html())
	history.add_text(mode_text(type, add_whisper))
	history.pop()
	
	history.push_color("#" + chat_colors[type].lightened(0.5).to_html())
	history.append_bbcode(str("[b]", author, ":[/b] "))
	history.pop()
	
	history.add_text(str(message, "\n"))

func parse_command(command):
	if command.begins_with("/g"):
		mode = Data.CHATS.GLOBAL
		update_mode()
		return true
	elif command.begins_with("/l"):
		mode = Data.CHATS.LOCAL
		return true
	elif command.begins_with("/w"):
		var split = command.split(" ", true, 1)
		if split.size() == 2:
			mode = Data.CHATS.WHISPER
			whisper = split[1]
	elif command.begins_with("/r"):
		mode = Data.CHATS.WHISPER
		whisper = last_whisper
		return true

func on_key_press(p_id, key, state):
	if state == Controls.State.ACTION:
		if key == Controls.CHAT:
			return activate()
		elif key == Controls.COMMAND:
			activate()
			input.text = "/"
			input.caret_position = 1
			return
		else:
			return
	elif state == Controls.State.CHAT:
		if key == Controls.ACCEPT:
			if input.text.begins_with("/"):
				parse_command(input.text)
			else:
				add_message(Com.player.uname, input.text, mode, mode == Data.CHATS.WHISPER)
				var packet = Packet.new(Packet.TYPE.CHAT).add_u8(mode).add_string(input.text)
				
				if mode == Data.CHATS.WHISPER:
					packet.add_string(whisper)
				
				packet.send()
			
			reset()
		elif key == Controls.CANCEL:
			reset()

func activate():
	Com.controls.state = Controls.State.CHAT
	update_mode()
	history.scroll_active = true
	chat_mode.visible = true
	input.placeholder_text = ""
	input.grab_focus()

func reset():
	input.text = ""
	history.scroll_active = false
	chat_mode.visible = false
	input.placeholder_text = PLACEHOLDER
	input.release_focus()
	
	if Com.controls.state == Controls.State.CHAT:
		Com.controls.state = Controls.State.ACTION

func mode_text(type, add_whisper):
	return str("[", default_chats[type], (" to " + whisper) if add_whisper else "", "] ")

func update_mode():
	chat_mode.modulate = chat_colors[mode]
	chat_mode.text = mode_text(mode, mode == Data.CHATS.WHISPER)

func on_text(new_text):
	if new_text.ends_with(" ") and parse_command(new_text):
		update_mode()
		input.text = ""