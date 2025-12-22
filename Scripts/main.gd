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
	for child in lobby_container.get_children():
		child.queue_free()

	var friend_lobbies: Dictionary = Network.get_lobbies_with_friends()
	
	if friend_lobbies.is_empty():
		var label = Label.new()
		label.text = "No hay amigos jugando."
		lobby_container.add_child(label)
		return

	# Iteramos sobre los IDs de los lobbies encontrados
	for lobby_steam_id in friend_lobbies:
		# Obtenemos los datos REALES desde Steam usando la ID del lobby
		var lobby_name = Steam.getLobbyData(lobby_steam_id, "name")
		if lobby_name == "":
			lobby_name = "Lobby Desconocido"
			
		var host_id = Steam.getLobbyOwner(lobby_steam_id)
		var host_name = Steam.getFriendPersonaName(host_id)
		
		# Crear el botón
		var lobby_item = Button.new()
		lobby_item.text = "%s - Host: %s" % [lobby_name, host_name]
		lobby_item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Conectar señal pasando la ID correcta
		lobby_item.pressed.connect(_on_lobby_item_pressed.bind(lobby_steam_id))
		
		lobby_container.add_child(lobby_item)
func _on_lobby_item_pressed(id: int) -> void:
	# Lógica para unirse al lobby
	Network.joint_lobby(id)
	Global.change_scene("res://Scenes/map.tscn")


func _on_id_pressed() -> void:
	Network.open_invite_menu()
