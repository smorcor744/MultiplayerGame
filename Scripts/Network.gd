extends Node

const PACKET_READ_LIMIT:int = 32

var is_host : bool = false
var lobby_id : int = 0
var lobby_members:Array = []
var lobby_members_max :int = 20

var peer = SteamMultiplayerPeer.new()

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_create)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)


func _process(_delta: float) -> void:
	if lobby_id > 0:
		read_all_p2p_packets()

func create_lobby():
	if lobby_id == 0:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY,lobby_members_max)
		print(lobby_id)


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
		Global.change_scene("res://Scenes/map.tscn")
		


func joint_lobby(this_lobby_id :int):
	Steam.joinLobby(this_lobby_id)
	
func _on_lobby_joined(this_lobby_id:int, _permissions:int,_locked:bool,response:int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		
		var host_id = Steam.getLobbyOwner(lobby_id)
		var my_steam_id = Steam.getSteamID()
		
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
		Global.change_scene("res://Scenes/map.tscn")


func get_lobby_members():
	lobby_members.clear()
	
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for member in range(0,num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id,member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({"steam_id":member_steam_id,"steam_name":member_steam_name})
	
	
func send_p2p_packet(this_target:int,packet_data:Dictionary, send_type:int = 0):
	var channel:int = 0
	
	var this_data:PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	
	if this_target == 0:
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member['steam_id'] != Global.steam_id:
					Steam.sendP2PPacket(member['steam_id'],this_data,send_type,channel)
	else:
		Steam.sendP2PPacket(this_target,this_data,send_type,channel)


func _on_p2p_session_request(remote_id:int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	
	Steam.acceptP2PSessionWithUser(remote_id)

func make_p2p_handshake():
	send_p2p_packet(0,{"message":"handshake", "steam_id":Global.steam_id, "username":Global.steam_username})

func read_all_p2p_packets(read_count:int =0):
	if read_count >= PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0)> 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count +1)


func read_p2p_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size,0)
		
		var packet_sender: int = this_packet['remote_steam_id']
		
		var packed_code:PackedByteArray = this_packet['data']
		var readable_data:Dictionary = bytes_to_var(packed_code)
		
		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("PLAYER: ", readable_data["username"], "HAS JOINED!!")
					get_lobby_members()
	
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
	
	
	
	
	
	
	
	
	
