extends Control

@onready var progress_bar = $ProgressBar

var target_scene_path: String
var loading_status: int
var progress: Array = [] # Godot requiere un Array para devolver el progreso (raro pero así es)

func _ready():
	# 1. Obtenemos la ruta desde nuestro Autoload
	target_scene_path = Global.next_scene_path
	
	if target_scene_path == "":
		push_error("¡No hay escena definida en Global.next_scene_path!")
		return

	# 2. Iniciamos la petición de carga en segundo plano
	# use_sub_threads: true hace que cargue más rápido usando múltiples núcleos
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta):
	# 3. Actualizamos el estado de la carga en cada frame
	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	# 4. Actualizamos la barra visual
	# progress[0] es un valor entre 0.0 y 1.0, así que multiplicamos por 100
	if progress.size() > 0:
		progress_bar.value = progress[0] * 100
	
	# 5. Verificamos si terminó
	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		# La carga terminó, obtenemos el recurso
		var new_scene_resource = ResourceLoader.load_threaded_get(target_scene_path)
		
		# Cambiamos a la nueva escena
		get_tree().change_scene_to_packed(new_scene_resource)
		
	elif loading_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error al cargar la escena.")
