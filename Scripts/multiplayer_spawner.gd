extends MultiplayerSpawner

@export var network_player: PackedScene
@export var server_player: PackedScene

var player: Player

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(id: int):
	if not multiplayer.is_server(): 
		return
	#Lobby.debug_log("player spawn: "+str(id))
	player = network_player.instantiate()
	player.name = str(id)
	get_node(spawn_path).add_child(player)
	
