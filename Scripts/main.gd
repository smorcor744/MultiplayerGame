extends Node


@onready var lobby_id: LineEdit = $LobbyID
@onready var join: Button = $Join
@onready var host: Button = $host
@onready var lobby_container: VBoxContainer = $Panel/LobbyContainer

func _ready() -> void:
	if !Global.steam_running :
		join.disabled = true
		host.disabled = true
		lobby_id.text = "Abre el Steam"

func _on_join_pressed() -> void:
	var id:int = int(lobby_id.text)
	Network.joint_lobby(id)
	


func _on_host_pressed() -> void:
	Network.create_lobby()
	


func _on_refresh_lobbies_pressed() -> void:
	# Limpiar lista anterior
	for child in lobby_container.get_children():
		child.queue_free()

	var friend_lobbies: Dictionary = Network.get_lobbies_with_friends()

	if friend_lobbies.is_empty():
		var label = Label.new()
		label.text = "No se encontraron lobbies de amigos."
		lobby_container.add_child(label)
		return

	# friend_lobbies es { lobby_id: [friend_id_1, friend_id_2] }
	for this_lobby_id in friend_lobbies:
		var lobby_name = Steam.getLobbyData(this_lobby_id, "name")
		
		# Obtenemos la ID del dueño del lobby
		var owner_id = Steam.getLobbyOwner(this_lobby_id)
		
		# VALIDACIÓN DE SEGURIDAD: Si la ID es 0, saltamos para evitar el error C++
		if owner_id <= 0:
			continue
			
		var owner_name = Steam.getFriendPersonaName(owner_id)
		
		var lobby_item = Button.new()
		lobby_item.text = "Lobby: %s - Host: %s" % [lobby_name, owner_name]
		lobby_item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Conectamos la señal pasando la ID correcta
		lobby_item.pressed.connect(_on_lobby_item_pressed.bind(this_lobby_id))
		
		lobby_container.add_child(lobby_item)




func _on_lobby_item_pressed(id: int) -> void:
	# Lógica para unirse al lobby
	Network.joint_lobby(id)
	Global.change_scene("res://Scenes/lobby.tscn")


func _on_id_pressed() -> void:
	Network.open_invite_menu()
