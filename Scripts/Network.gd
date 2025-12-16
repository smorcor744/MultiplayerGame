extends Node

const PACKET_READ_LIMIT:int = 32

var is_host : bool = false
var lobby_id : int = 0
var lobby_members:Array = []
var lobby_members_max :int = 20

var peer = SteamMultiplayerPeer.new()


signal player_joined(user,message)


func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_create)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_joined_requested)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()


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
		
		Steam.setLobbyJoinable(lobby_id,true)
		
		Steam.setLobbyData(lobby_id,"name","Sergio lobby")
		var error = peer.create_host(0)
		
		if error == OK:
			multiplayer.multiplayer_peer = peer # Le decimos a Godot que use Steam
			print("Host iniciado correctamente")
		else:
			print("Error al iniciar host",error)
		Global.change_scene("res://Scenes/lobby.tscn")
		

func _on_lobby_joined_requested(friend_lobby_id: int, friend_id: int):
	print("Intentando unirse a lobby: ", friend_lobby_id,"ID Friend",friend_id)
	Steam.joinLobby(friend_lobby_id)

func joint_lobby(this_lobby_id :int):
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id:int, _permissions:int,_locked:bool,response:int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
		var host_id = Steam.getLobbyOwner(lobby_id)
		var my_steam_id = Steam.getSteamID()
		emit_signal("player_joined",Global.steam_username,"Se esta uniendo...")
		if host_id == my_steam_id:
			print("soy el host")
			return
		multiplayer.multiplayer_peer = null
		var error = peer.create_client(host_id, 0)
		if error == OK:
			multiplayer.multiplayer_peer = peer # Le decimos a Godot que use Steam
			print("Conectado como cliente al Host: ", host_id)
		else:
			print("Error al iniciar cliente" , error)
			
		# Cambiamos a la misma escena del juego
		Global.change_scene("res://Scenes/lobby.tscn")


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
	
	
	
	
	
	
