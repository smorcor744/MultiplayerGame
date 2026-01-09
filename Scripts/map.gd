extends Node2D

@export var player_scene: PackedScene

@onready var multiplayer_spawner: MultiplayerSpawner = $Spawners/MultiplayerSpawner
@onready var players_container: Node2D = $Players

func _ready():
	multiplayer_spawner.spawn_function = _spawn_player_function
	
	if multiplayer.is_server():
		print("Soy el Host, iniciando spawns...")
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		var all_peers = multiplayer.get_peers()
		all_peers.append(1)
		
		for peer_id in all_peers:
			_on_peer_connected(peer_id)


func _spawn_player_function(data) -> Node:
	var peer_id = data.id   
	var spawn_pos = data.pos 
	
	var player = player_scene.instantiate()
	
	player.name = str(peer_id)
	player.position = spawn_pos  
	player.set_multiplayer_authority(peer_id)
	
	print("Spawn ejecutado para ID: ", peer_id, " en pos: ", spawn_pos)
	return player

func _on_peer_connected(id: int):
	# Obtenemos todos los puntos de spawn
	var puntos = get_tree().get_nodes_in_group("PuntosSpawn")
	print(puntos)
	# Elegimos uno al azar (o podrías usar un contador para ir en orden)
	var punto_elegido = puntos.pick_random()
	punto_elegido.remove_from_group("PuntosSpawn")
	var datos_spawn = {
		"id": id,
		"pos": punto_elegido.global_position
	}
	
	multiplayer_spawner.spawn(datos_spawn)

func _on_peer_disconnected(id: int):
	print("Jugador desconectado: ", id)
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.queue_free()
