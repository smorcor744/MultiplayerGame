extends Node

var steam_id:int = 0
var steam_username : String = ""

func _init() -> void:
	OS.set_environment("SteamAppID",str(480))
	OS.set_environment("SteamGameID",str(480))


func _ready() -> void:
	Steam.steamInit()
	
	if !Steam.isSteamRunning():
		print("STEAM IS NOT RUNNING!!")
		return

	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()
	
	
	print("STEAM USERNAME: ",steam_username)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
