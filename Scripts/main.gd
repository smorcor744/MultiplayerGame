extends Node2D


@onready var lobby_id: LineEdit = $LobbyID

func _on_join_pressed() -> void:
	var id:int = int(lobby_id.text)
	Network.joint_lobby(id)


func _on_host_pressed() -> void:
	Network.create_lobby()
