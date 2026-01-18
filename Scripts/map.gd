extends Node2D

@export var player_scene: PackedScene
@export var pelota: PackedScene


@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

@onready var spawner_1: Marker2D = $Players
@onready var spawner_2: Marker2D = $Players2
@onready var spawner_3: Marker2D = $Players3
@onready var spawner_4: Marker2D = $Players4

@onready var red_spawners = [$Players3,$Players2] 
@onready var blue_spawners = [$Players,$Players4]
var red_team = {}
var blue_team = {}
@onready var players_container = self 
@onready var pelota_actual = $Pelota
var gol = false
var red_gols = 0
var blue_gols = 0


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
	var color: Color
	if punto_elegido.is_in_group("Red"):
		color = Color.RED
	else:
		color = Color.BLUE
		
	
	punto_elegido.remove_from_group("PuntosSpawn")
	
	var datos_spawn = {
		"id": id,
		"pos": punto_elegido.global_position,
		"color":color,
	}
	
	multiplayer_spawner.spawn(datos_spawn)

func _spawn_player_function(data) -> Node:
	var peer_id = data.id   
	var spawn_pos = data.pos 
	var color = data.color 
	
	var player = player_scene.instantiate()
	
	player.name = str(peer_id)
	player.position = spawn_pos  
	player.modulate = color  
	if color == Color.BLUE:
		player.add_to_group("Blue")
		blue_team[peer_id] = spawn_pos
	else:
		player.add_to_group("Red")
		red_team[peer_id] = spawn_pos
		
	player.set_multiplayer_authority(peer_id)
	
	return player

func _on_peer_disconnected(id: int):
	print("Jugador desconectado: ", id)
	if players_container.has_node(str(id)):
		players_container.get_node(str(id)).queue_free()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.queue_free()


func respawn_players():
	timer_between()
	#Red
	spawner_2.add_to_group("PuntosSpawn")
	spawner_3.add_to_group("PuntosSpawn")
	
	#Blue
	spawner_4.add_to_group("PuntosSpawn")
	spawner_1.add_to_group("PuntosSpawn")
	var players = get_tree().get_nodes_in_group("Player")

	for player in players:
		var id = int(player.name)
		if red_team.has(id):
			player.position = red_team[id]
		if blue_team.has(id):
			player.position = blue_team[id]
	
	#if red_team.size() >1:
		#var player1 = _get_data_player("Red")
		#multiplayer_spawner.spawn(player1)
		#
		#var player2 = _get_data_player("Red")
		#multiplayer_spawner.spawn(player2)
	#elif red_team.size() >=1:
		#var player1 = _get_data_player("Red")
		#multiplayer_spawner.spawn(player1)
	#
	#if blue_team.size() >1:
		#var player1 = _get_data_player("Blue")
		#multiplayer_spawner.spawn(player1)
		#
		#var player2 = _get_data_player("Blue")
		#multiplayer_spawner.spawn(player2)
	#elif red_team.size() >=1:
		#var player1 = _get_data_player("Red")
		#multiplayer_spawner.spawn(player1)

func _get_data_player(team:String):
	var datos = {}
	if team == "Red":
		var player = red_team.pick_random()
		datos = {
			"id": player.name.to_int(),
			"pos": red_spawners.pick_random().global_position,
			"color":Color.RED,
		}
	else:
		var player = red_team.pick_random()
		datos = {
			"id": player.name.to_int(),
			"pos": blue_spawners.pick_random().global_position,
			"color":Color.BLUE,
		}
	return datos


func timer_between():
	get_tree().paused = true

	var segundos = 3
	$Panel.visible = true
	for i in range(segundos):
		$Panel/Label.text = str(segundos - i)
		await get_tree().create_timer(1.0).timeout
		
	$Panel/Label.text = "Jugar!!"
	
	await get_tree().create_timer(0.5).timeout
	$Panel.visible = false
	get_tree().paused = false
	gol = false

func _on_fuera_body_exited(body: Node2D) -> void:

	if body.is_in_group("Pelota") and gol == false:
		print("fuera")
		$Panel/Label.text = "Fuera!!"
		$Panel.visible = true
		await get_tree().create_timer(1.0).timeout
		timer_between()
		pelota_actual.queue_free()
		pelota_actual = pelota.instantiate() 
		$ball.call_deferred("add_child", pelota_actual)
		respawn_players()
		


func _on_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("Pelota") and gol == false:
		print("gool")
		blue_gols += 1
		$Marcador.text = "%d : %d" % [red_gols, blue_gols]
		gol = true
		$Panel/Label.text = "Goool!!"
		$Panel.visible = true
		await get_tree().create_timer(1.0).timeout
		timer_between()
		pelota_actual.queue_free()
		pelota_actual = pelota.instantiate() 
		$ball.call_deferred("add_child", pelota_actual)
		respawn_players()
		

func _on_right_body_entered(body: Node2D) -> void:
	if body.is_in_group("Pelota") and gol == false:
		print("gool")
		red_gols += 1
		$Marcador.text = "%d : %d" % [red_gols, blue_gols]
		gol = true
		$Panel/Label.text = "Goool!!"
		$Panel.visible = true
		await get_tree().create_timer(1.0).timeout
		timer_between()
		pelota_actual.queue_free()
		pelota_actual = pelota.instantiate() 
		$ball.call_deferred("add_child", pelota_actual)
		respawn_players()
		
