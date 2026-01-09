extends Node2D

@export var player_scene: PackedScene

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner


@onready var players_container = self 

func _ready():
	multiplayer_spawner.spawn_function = _spawn_player_function
	
	if multiplayer.is_server():
		print("Soy el Host, esperando clientes...")
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		_spawnear_jugador(1)
		
	else:
		rpc_id(1, "cliente_listo_para_jugar")

@rpc("any_peer", "call_local", "reliable")
func cliente_listo_para_jugar():
	if multiplayer.is_server():
		var id_jugador = multiplayer.get_remote_sender_id()
		_spawnear_jugador(id_jugador)

func _spawnear_jugador(id: int):
	if players_container.has_node(str(id)):
		return

	var puntos = get_tree().get_nodes_in_group("PuntosSpawn")
	
	if puntos.size() == 0:
		print("ERROR: No quedan puntos de spawn")
		return

	var punto_elegido = puntos.pick_random()
	punto_elegido.remove_from_group("PuntosSpawn")
	
	var datos_spawn = {
		"id": id,
		"pos": punto_elegido.global_position
	}
	
	multiplayer_spawner.spawn(datos_spawn)

func _spawn_player_function(data) -> Node:
	var peer_id = data.id   
	var spawn_pos = data.pos 
	
	var player = player_scene.instantiate()
	
	player.name = str(peer_id)
	player.position = spawn_pos  
	player.set_multiplayer_authority(peer_id)
	
	return player

func _on_peer_disconnected(id: int):
	print("Jugador desconectado: ", id)
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.queue_free()
