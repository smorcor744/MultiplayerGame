extends Node

var steam_id:int = 0
var steam_username : String = ""
var game_id = "480"

var steam_running = false

func _init() -> void:
	OS.set_environment("SteamAppID",game_id)
	OS.set_environment("SteamGameID",game_id)


func _ready() -> void:
	Steam.steamInit()
	
	if !Steam.isSteamRunning():
		print("STEAM IS NOT RUNNING!!")
		return
	steam_running = true
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	
	print("STEAM USERNAME: ",steam_username)

func _process(_delta: float) -> void:
	Steam.run_callbacks()


func change_scene(path: String):
	get_tree().change_scene_to_file(path)
