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
	Global.change_scene("res://Scenes/lobby.tscn")
	
func _on_connection_failed():
	print("FALLO en la conexión al servidor")
	leave_lobby()


func create_lobby():
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY,lobby_members_max)
		print(lobby_id)
		

func open_invite_menu():
	Steam.activateGameOverlay("LobbyInvite")


func _on_lobby_create(connectd: int, this_lobby_id: int):
	if connectd == 1:
		lobby_id = this_lobby_id
		print("Lobby creado ID: ", lobby_id)
		
		# Configurar Host
		peer = SteamMultiplayerPeer.new()
		var error = peer.create_host(0)
		
		if error == OK:
			multiplayer.multiplayer_peer = peer
			
			# Configurar datos de Steam
			Steam.setLobbyJoinable(lobby_id, true)
			Steam.setLobbyData(lobby_id, "name", Global.steam_username + "'s lobby")
			
			# El host entra directo al lobby
			Global.change_scene("res://Scenes/lobby.tscn")
			# Pequeña espera para asegurar que la escena cargó antes de emitir
			await get_tree().process_frame 
			emit_signal("player_joined", Global.steam_id)
		else:
			print("Error al iniciar host: ", error)




func _on_lobby_joined_requested(friend_lobby_id: int, friend_id: int):
	print("Intentando unirse a lobby: ", friend_lobby_id,"ID Friend",friend_id)
	Steam.joinLobby(friend_lobby_id)

func join_lobby(this_lobby_id :int):
	Steam.joinLobby(this_lobby_id)


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		var host_id = Steam.getLobbyOwner(lobby_id)
		
		# Si soy el dueño, no hago nada (ya lo manejó create_lobby)
		if host_id == Steam.getSteamID():
			return 
		
		print("Lobby Steam unido. Conectando a Host Godot: ", host_id)
		
		# Pantalla de carga mientras conectamos
		Global.change_scene("res://Scenes/LoadingScene.tscn")
		
		# Crear Cliente
		peer = SteamMultiplayerPeer.new() # Usamos la variable global 'peer'
		var error = peer.create_client(host_id, 0)
		
		if error == OK:
			multiplayer.multiplayer_peer = peer
			print("Esperando señal 'connected_to_server'...")

		else:
			print("Error al crear cliente: ", error)


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
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	
	# Cerrar peer de Godot
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	peer = null
	is_host = false
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
	print("Iniciando juego, cargando mapa...")
	Global.change_scene(game_scene_path)
	
	
	
	
	
	
