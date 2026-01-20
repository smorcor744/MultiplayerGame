extends Control
@onready var friends_container: VBoxContainer = $ScrollContainer/Friends
@onready var chat: RichTextLabel = $Vbox/RichTextLabel
@onready var message: LineEdit = $Vbox/HBoxContainer/Message
var path = null

func _ready() -> void:
	name = "Lobby" 
	
	_on_refresh_lobbies_pressed()
	Network.player_joined.connect(_on_player_joined_lobby)
	
	if multiplayer.multiplayer_peer:
		var status = multiplayer.multiplayer_peer.get_connection_status()
		if status == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc("update_chat", Global.steam_username, "se ha unido a la lobby.")
		elif status == MultiplayerPeer.CONNECTION_CONNECTING:
			multiplayer.connected_to_server.connect(_on_conexion_completada, CONNECT_ONE_SHOT)


# Función auxiliar para enviar el mensaje solo cuando la conexión termine
func _on_conexion_completada():
	rpc("update_chat",Global.steam_username, "se ha unido a la lobby.")



@rpc("any_peer","call_local","reliable")
func update_chat(username:String,mensaje:String):
	chat.text += str(username+": " + mensaje +"\n")

func _on_player_joined_lobby(steam_id: int) -> void:
	var friend_name = Steam.getFriendPersonaName(steam_id)

	chat.text += str("[SISTEMA]: " + friend_name + " se unió.\n")


func _on_refresh_lobbies_pressed() -> void:
	for child in friends_container.get_children():
		child.queue_free()
		
	var friends: Array = Steam.getUserSteamFriends()

	for friend in friends:
		if friend["status"] == 0:
			continue 
			
		var friend_data = friend
		var friend_name = friend_data["name"]
		var friend_id = friend_data["id"]


		var row_panel = PanelContainer.new()
		row_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 10) 
		row_panel.add_child(hbox)
		

		var name_label = Label.new()
		name_label.text = str(friend_name)

		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)
		

		var invite_btn = Button.new()
		invite_btn.text = "Invite"
		invite_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		invite_btn.pressed.connect(_on_lobby_item_pressed.bind(friend_id))
		hbox.add_child(invite_btn)
		

		friends_container.add_child(row_panel)


func _on_lobby_item_pressed(friend_steam_id:int) -> void:
	# Lógica para unirse al lobby
	var my_lobby_id = Network.lobby_id
	if my_lobby_id == 0:
		print("No hay lobby")
		return
	var success = Steam.inviteUserToLobby(my_lobby_id,friend_steam_id)
	if success:
		print("Invitation sended to ", friend_steam_id)
	else:
		print("Error al enviar la invitacion")
	print("INVITATION SENDED")

func _on_start_game_pressed() -> void:
	if multiplayer.is_server():
		$StartGame/HBoxContainer.visible = true


func _on_exit_lobby_pressed() -> void:
	Network.leave_lobby()
	

func _on_refresh_pressed() -> void:
	_on_refresh_lobbies_pressed()


func _on_send_pressed() -> void:
	# 1. Verificamos si existe el peer
	if not multiplayer.has_multiplayer_peer():
		chat.text += "[ERROR]: No hay sistema multijugador iniciado.\n"
		return
	
	# 2. CORRECCIÓN: Verificamos si el estado es realmente CONECTADO
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		chat.text += "[SISTEMA]: Todavía conectando con el servidor, espera un momento...\n"
		return

	# Si pasa las comprobaciones, enviamos
	send_message()

func send_message():
	if message.text.strip_edges() != "":
		rpc("update_chat",Global.steam_username, message.text)
		message.text = ""


func _on_message_text_submitted(_new_text: String) -> void:
	send_message()


@rpc("authority","call_local", "reliable")
func start_game(game_scene_path:String):
	
	Global.change_scene(game_scene_path)


func _on_sumo_pressed() -> void:
	path = "res://Scenes/map_topdown.tscn"
	Network.rpc("start_game", path)


func _on_futbol_pressed() -> void:
	path = "res://Scenes/futbol.tscn"
	Network.rpc("start_game", path)


func _on_fight_pressed() -> void:
	path = "res://Scenes/map.tscn"
	Network.rpc("start_game", path)
