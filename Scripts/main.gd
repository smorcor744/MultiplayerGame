extends Node


@onready var lobby_id: LineEdit = $LobbyID
@onready var join: Button = $Join
@onready var host: Button = $host

func _ready() -> void:
	if !Global.steam_running :
		join.disabled = true
		host.disabled = true

func _on_join_pressed() -> void:
	var id:int = int(lobby_id.text)
	Network.joint_lobby(id)
	
	Global.change_scene("res://Scenes/map.tscn")


func _on_host_pressed() -> void:
	Network.create_lobby()
	Global.change_scene("res://Scenes/map.tscn")
