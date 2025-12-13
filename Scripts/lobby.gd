extends Control
@onready var friends_container: VBoxContainer = $ScrollContainer/Friends

func _ready() -> void:
	_on_refresh_lobbies_pressed()


func _on_refresh_lobbies_pressed() -> void:
	for child in friends_container.get_children():
		child.queue_free()
		
	var friends: Array = Steam.getUserSteamFriends()

	for friend in friends:
		if friend["status"] == 0:
			continue 
			
		var friend_data = friend
		var friend_name = friend_data["name"]
		var friend_id = friend_data["id"]


		var row_panel = PanelContainer.new()
		
		var hbox = HBoxContainer.new()

		hbox.add_theme_constant_override("separation", 10) 
		row_panel.add_child(hbox)
		

		var name_label = Label.new()
		name_label.text = str(friend_name)


		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(name_label)
		

		var invite_btn = Button.new()
		invite_btn.text = "Invite"

		invite_btn.pressed.connect(_on_lobby_item_pressed.bind(friend_id))
		hbox.add_child(invite_btn)
		

		friends_container.add_child(row_panel)


func _on_lobby_item_pressed(friend_steam_id:int) -> void:
	# Lógica para unirse al lobby
	var my_lobby_id = Network.lobby_id
	if my_lobby_id == 0:
		print("No hay lobby")
		return
	var success = Steam.inviteUserToLobby(my_lobby_id,friend_steam_id)
	if success:
		print("Invitation sended to", friend_steam_id)
	else:
		print("Error al enviar la invitacion")
	print("INVITATION SENDED")


func _on_start_game_pressed() -> void:
	Global.change_scene("res://Scenes/map.tscn")


func _on_exit_lobby_pressed() -> void:
	Network.leave_lobby()
	

func _on_refresh_pressed() -> void:
	_on_refresh_lobbies_pressed()
