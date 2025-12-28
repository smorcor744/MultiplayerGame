# spawner.gd - VERSIÓN CORREGIDA
extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	# Configurar el spawner
	spawn_function = _spawn_player_custom
	print("MultiplayerSpawner listo en ruta: ", spawn_path)

func _spawn_player_custom(data) -> Node:
	# data debería ser el peer_id
	var peer_id = data
	print("Spawneando jugador para peer: ", peer_id)
	
	var player = network_player.instantiate()
	player.name = str(peer_id)
	
	# Asegurar que tenga MultiplayerSynchronizer
	if not player.has_node("MultiplayerSynchronizer"):
		var sync = MultiplayerSynchronizer.new()
		sync.name = "MultiplayerSynchronizer"
		player.add_child(sync, true)
	
	return player
