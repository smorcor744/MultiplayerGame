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
	var peer_id = data
	var player = player_scene.instantiate()
	
	player.name = str(peer_id) 
	
	player.position = Vector2(100, 100) 
	
	player.set_multiplayer_authority(peer_id)
	
	print("Spawn function ejecutada para ID: ", peer_id)
	return player

func _on_peer_connected(id: int):
	print("Solicitando spawn para ID: ", id)
	multiplayer_spawner.spawn(id)

func _on_peer_disconnected(id: int):
	print("Jugador desconectado: ", id)
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()




func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.queue_free()
