extends Node2D
const PLAYER = preload("uid://dh8pwqukj5i7o")
@onready var multiplayer_spawner = $Spawners/MultiplayerSpawner  # Asegúrate de que existe
@export var player_scene: PackedScene

func _ready():
	if has_node("MultiplayerSpawner"):
		multiplayer_spawner = $MultiplayerSpawner
		multiplayer_spawner.spawn_function = _custom_spawn_player

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
func _custom_spawn_player(data) -> Node:
	var peer_id = data
	print("Spawneando jugador custom para: ", peer_id)
	
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	return player
func _add_player(id: int):
	print("Añadiendo jugador con ID: ", id)
	
	if has_node("MultiplayerSpawner"):
		# Usar el spawner
		multiplayer_spawner.spawn(id)
	else:
		# Fallback: crear manualmente
		var player = player_scene.instantiate()
		player.name = str(id)
		
		# Asegurar MultiplayerSynchronizer
		if not player.has_node("MultiplayerSynchronizer"):
			var sync = MultiplayerSynchronizer.new()
			sync.name = "MultiplayerSynchronizer"
			player.add_child(sync, true)
		
		$Players.add_child(player, true)
		print("Jugador añadido manualmente: ", player.name)

func _remove_player(id: int):
	print("Removiendo jugador: ", id)
	if $Players.has_node(str(id)):
		$Players.get_node(str(id)).queue_free()
