extends Node2D

# Referencia a la escena del jugador
@export var player_scene: PackedScene

# Referencias a nodos hijos
@onready var multiplayer_spawner: MultiplayerSpawner = $Spawners/MultiplayerSpawner
@onready var players_container: Node2D = $Players

func _ready():
	# 1. Configurar la función de spawn (Tanto en Cliente como en Servidor)
	multiplayer_spawner.spawn_function = _spawn_player_function
	
	# 2. Lógica exclusiva del SERVIDOR (HOST)
	if multiplayer.is_server():
		print("Soy el Host, iniciando spawns...")
		
		# Conectar señales para cuando alguien entra/sale DESPUÉS de cargar el mapa
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		# 3. Spawnear a los jugadores que YA están conectados (incluyendo al Host)
		# Creamos una lista con todos los IDs: El Host (1) + Los Clientes
		var all_peers = multiplayer.get_peers()
		all_peers.append(1) # Agregamos al Host (ID 1) a la lista
		
		for peer_id in all_peers:
			_on_peer_connected(peer_id)

# Esta función es llamada automáticamente por el MultiplayerSpawner
# Se ejecuta en el Servidor y el resultado se replica en los Clientes
func _spawn_player_function(data) -> Node:
	var peer_id = data
	var player = player_scene.instantiate()
	
	# Es vital que el nombre sea el ID para facilitar búsquedas
	player.name = str(peer_id) 
	
	# Configura la posición inicial si es necesario
	player.position = Vector2(100, 100) # O usa puntos de spawn aleatorios
	
	# Importante: Asignar la autoridad para que cada jugador controle su muñeco
	player.set_multiplayer_authority(peer_id)
	
	print("Spawn function ejecutada para ID: ", peer_id)
	return player

# Cuando alguien entra (o al iniciar el mapa para los que ya están)
func _on_peer_connected(id: int):
	print("Solicitando spawn para ID: ", id)
	# Solo llamamos a spawn() en el spawner. Él se encarga del resto.
	multiplayer_spawner.spawn(id)

# Cuando alguien se desconecta
func _on_peer_disconnected(id: int):
	print("Jugador desconectado: ", id)
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()
