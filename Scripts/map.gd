extends Node2D # O Node2D

func _ready():
	# Solo el servidor (Host) tiene autoridad para crear jugadores
	if multiplayer.is_server():
		# Conectar señal cuando alguien entra
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		
		# Spawneate a ti mismo (Host)
		_add_player(1) # 1 es siempre la ID del host en Godot

		# Si ya hay gente conectada antes de cargar el mapa:
		for id in multiplayer.get_peers():
			_add_player(id)

func _add_player(id: int):
	var player = preload("res://Scenes/Player.tscn").instantiate()
	player.name = str(id) # IMPORTANTE: El nombre debe ser la ID de red
	$Players.add_child(player) # El MultiplayerSpawner detectará esto y lo replicará a todos

func _remove_player(id: int):
	if $Players.has_node(str(id)):
		$Players.get_node(str(id)).queue_free()
