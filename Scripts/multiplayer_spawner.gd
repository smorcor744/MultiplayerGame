extends MultiplayerSpawner

@export var network_player: PackedScene
@export var server_player: PackedScene

var player: Player

func _ready() -> void:
	multiplayer.peer_connected.connect(spawn_player)

func spawn_player(id: int):
	if not multiplayer.is_server(): 
		return
	player = network_player.instantiate()
	var posx = -180 if id==1 else 360
	player.spawn_position = Vector2(posx, 0)

	player.name = str(id)
	get_node(spawn_path).call_deferred("add_child", player)
