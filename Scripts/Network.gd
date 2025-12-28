extends Node

const PACKET_READ_LIMIT:int = 32

var is_host : bool = false
var lobby_id : int = 0
var lobby_members:Array = []
var lobby_members_max :int = 20

var peer : SteamMultiplayerPeer


signal player_joined(user)
signal lobby_player_update(type, user_id)


func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_create)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_joined_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
func _on_connected_to_server():
	print("¡CONEXIÓN EXITOSA al servidor!")

func _on_connection_failed():
	print("FALLO en la conexión al servidor")
	leave_lobby()

func _on_lobby_chat_update(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int):
	# chat_state 1 = Entró, 2 = Salió, 8 = Desconectado
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("Usuario " + str(change_id) + " ha entrado.")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT or chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		print("Usuario " + str(change_id) + " ha salido.")
	
	# Emitimos señal para que la UI (lobby.gd) se actualice
	emit_signal("lobby_player_update", chat_state, change_id)

func create_lobby():
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY,lobby_members_max)
		print(lobby_id)
		

func open_invite_menu():
	Steam.activateGameOverlay("LobbyInvite")


func _on_lobby_create(connectd: int, this_lobby_id:int):
	print("CREATING LOBBY...")
	if connectd == 1:
		lobby_id = this_lobby_id
		print(lobby_id)
		await get_tree().process_frame

		peer = SteamMultiplayerPeer.new()
		Steam.setLobbyJoinable(lobby_id,true)
		
		Steam.setLobbyData(lobby_id,"name",Global.steam_username +"lobby")
		var error = peer.create_host(0)
		
		if error == OK:
			multiplayer.multiplayer_peer = peer # Le decimos a Godot que use Steam
			print("Host iniciado correctamente")
		else:
			print("Error al iniciar host",error)
		emit_signal("player_joined",Global.steam_id)
		
		Global.change_scene("res://Scenes/lobby.tscn")
		emit_signal("player_joined",Global.steam_id)




func _on_lobby_joined_requested(friend_lobby_id: int, friend_id: int):
	print("Intentando unirse a lobby: ", friend_lobby_id,"ID Friend",friend_id)
	Steam.joinLobby(friend_lobby_id)

func joint_lobby(this_lobby_id :int):
	Steam.joinLobby(this_lobby_id)
	
# REEMPLAZA la función _on_lobby_joined con esta versión corregida:
func _on_lobby_joined(this_lobby_id:int, _permissions:int, _locked:bool, response:int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		var host_id = Steam.getLobbyOwner(lobby_id)
		var my_steam_id = Steam.getSteamID()
		
		print("Lobby unido exitosamente. Host ID: ", host_id)
		print("Mi Steam ID: ", my_steam_id)
		
		# Si soy el host, ya tengo el servidor creado
		if host_id == my_steam_id:
			print("Soy el host, ya tengo servidor activo.")
			return
		
		# IMPORTANTE: Esperar un frame para asegurar que Steam está listo
		await get_tree().process_frame
		
		# Crear nuevo peer para el cliente
		var new_peer = SteamMultiplayerPeer.new()
		
		# Configurar el cliente
		var error = new_peer.create_client(host_id, 0)
		print("Intentando conectar como cliente. Error code: ", error)
		
		if error == OK:
			# Esperar a que la conexión esté lista
			await get_tree().create_timer(0.5).timeout
			
			multiplayer.multiplayer_peer = new_peer
			peer = new_peer
			
			print("Conexión establecida con el host")
			print("Estado de conexión: ", multiplayer.multiplayer_peer.get_connection_status())
			
			# Cambiar escena solo si estamos conectados
			if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				Global.change_scene("res://Scenes/lobby.tscn")
			else:
				print("ERROR: No conectado después de crear cliente")
		else:
			print("Error crítico al crear cliente: ", error)


func get_lobby_members():
	lobby_members.clear()
	
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(0,num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({"steam_id":member_steam_id,"steam_name":member_steam_name})
	
	
func check_command_line():
	var args = OS.get_cmdline_args()
	
	for i in range(args.size()):
		if args[i]== "+connect_lobby":
			if args.size() > i+1:
				var friend_lobby_id = int(args[i +1])
				print("Lanzado desde invitación. Uniendo a: ", lobby_id)
				Steam.joinLobby(friend_lobby_id)
	

func leave_lobby():
	if lobby_id == 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	multiplayer.multiplayer_peer = null
	
	Global.change_scene("res://Scenes/main.tscn")

func _on_server_disconnected():
	leave_lobby()


func get_lobbies_with_friends() -> Dictionary:
	var results: Dictionary = {}

	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)

		if game_info.is_empty():
			# This friend is not playing a game
			continue
		else:
			# They are playing a game, check if it's the same game as ours
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']

			if app_id != Steam.getAppID() or lobby is String:
				# Either not in this game, or not in a lobby
				continue

			if not results.has(lobby):
				results[lobby] = []

			results[lobby].append(steam_id)

	return results
	

@rpc("call_local", "reliable")
func start_game(game_scene_path:String):
	
	Global.change_scene(game_scene_path)
	
	
	
	
	
	
