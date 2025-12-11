extends Node


@onready var lobby_id: LineEdit = $LobbyID
@onready var join: Button = $Join
@onready var host: Button = $host
@onready var lobby_container: VBoxContainer = $Panel/LobbyContainer

func _ready() -> void:
	if !Global.steam_running :
		join.disabled = true
		host.disabled = true

func _on_join_pressed() -> void:
	var id:int = int(lobby_id.text)
	Network.joint_lobby(id)
	
	Global.change_scene("res://Scenes/map.tscn")


func _on_host_pressed() -> void:
	Network.create_lobby()
	Global.change_scene("res://Scenes/map.tscn")


func _on_refresh_lobbies_pressed() -> void:
	# 1. Limpiar la lista anterior
	for child in lobby_container.get_children():
		child.queue_free()

	# 2. Obtener los lobbies de amigos (asumiendo que Global existe y tiene la función)
	var friend_lobbies: Dictionary = Network.get_lobbies_with_friends()
	
	if friend_lobbies.is_empty():
		print("No se encontraron lobbies de amigos.")
		# Opcional: mostrar un mensaje en la UI
		var label = Label.new()
		label.text = "No hay lobbies disponibles"
		lobby_container.add_child(label)
		return

	# 3. Iterar sobre el diccionario y crear elementos para la UI
	for id in friend_lobbies:
		var lobby_data = friend_lobbies[lobby_id]
		
		# Crea un nuevo elemento para la lista (por ejemplo, un botón)
		var lobby_item = Button.new()
		
		# Asume que lobby_data puede contener el nombre o el dueño
		var lobby_name = lobby_data.get("name", "Lobby sin nombre")
		var owner_steam_name = lobby_data.get("owner_name", "Desconocido") # Esto es un ejemplo de dato

		lobby_item.text = "Lobby: %s (ID: %s) - Host: %s" % [lobby_name, id, owner_steam_name]
		
		# Conectar la señal de presionar para unirse
		lobby_item.pressed.connect(
			func():
				_on_lobby_item_pressed(id)
		)
		
		# Añadir a tu contenedor
		lobby_container.add_child(lobby_item)

func _on_lobby_item_pressed(id: int) -> void:
	# Lógica para unirse al lobby
	Network.joint_lobby(id)
	Global.change_scene("res://Scenes/map.tscn")
