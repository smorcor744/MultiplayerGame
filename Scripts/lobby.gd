extends Control
@onready var friends_container: VBoxContainer = $InvitePanel/Friends

func _ready() -> void:
	_on_refresh_lobbies_pressed()


func _on_refresh_lobbies_pressed() -> void:
	for child in friends_container.get_children():
		child.queue_free()
	print(Steam.getUserSteamFriends())
	var friends: Array = Steam.getUserSteamFriends()


	for friend in friends:
		print("1")
		var friend_data = friend
		
		# Crea un nuevo elemento para la lista 
		var friend_item = Button.new()
		
		var friend_name = friend_data["name"]
		var friend_id = friend_data["id"]
		var friend_status = friend_data["status"]
		friend_item.text = "Friend: %s (ID: %s) - Status: %s" % [friend_name, friend_id, friend_status]
		
		# Conectar la señal de presionar para unirse
		friend_item.pressed.connect(
			func():
				_on_lobby_item_pressed()
		)
		
		# Añadir a tu contenedor
		friends_container.add_child(friend_item)


func _on_lobby_item_pressed() -> void:
	# Lógica para unirse al lobby
	print("INVITATION SENDED")
