extends Node

# --- DEFINICIÓN DE SEÑALES ---
# Necesarias para que otros nodos escuchen las órdenes
signal orden_marchar
signal orden_atacar
signal orden_defenda
signal orden_fallida
signal beat_acertado(tipo) # Para animaciones visuales (feedback)
signal nuevo_beat(beat_index) # Señal para el metrónomo visual 

# --- CONFIGURACIÓN ---
@export var bpm: int = 120
@export var tolerance: float = 0.30 # 150ms (ventana de éxito)
var last_beat_monitored = -1 # Para saber qué beat ya notificamos

# Variables calculadas
var beat_interval = 0.0
var last_hit_beat_index = -1 # Para evitar spamear el mismo beat

# Estado
var command_buffer = [] # Buffer: ["Pata", "Pata", "Pata", "Pon"]

@onready var music_player = $AudioStreamPlayer

func _ready():
	# Calculamos cuánto dura un beat al inicio
	beat_interval = 60.0 / bpm
	connect("nuevo_beat", _on_nuevo_beat)
	# Aseguramos que la música suene (o la activas tú manualmente)
	if not music_player.playing:
		music_player.play()

func _physics_process(_delta: float):
	# Si no hay música, no procesamos
	if not music_player.playing:
		return

	# 1. MATEMÁTICAS DEL RITMO
	var song_pos = music_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	# Compensar latencia de audio 
	song_pos -= AudioServer.get_output_latency()
	
	# Calculamos el beat actual (entero)
	var current_beat = int(song_pos / beat_interval)
	
	# Si hemos entrado en un nuevo beat que no hemos avisado aún...
	if current_beat > last_beat_monitored:
		last_beat_monitored = current_beat
		emit_signal("nuevo_beat", current_beat) # ¡Avisamos a la UI!
	
	var closest_beat_index = round(song_pos / beat_interval)
	var closest_beat_time = closest_beat_index * beat_interval
	var time_diff = abs(song_pos - closest_beat_time)

	# 2. DETECCIÓN DE INPUTS

	if Input.is_action_just_pressed("ui_up"):
		intentar_beat("Pata", time_diff, closest_beat_index)
	elif Input.is_action_just_pressed("ui_down"):
		intentar_beat("Pon", time_diff, closest_beat_index)
	elif Input.is_action_just_pressed("ui_left"):
		intentar_beat("Chaka", time_diff, closest_beat_index)
	elif Input.is_action_just_pressed("ui_right"):
		intentar_beat("Don", time_diff, closest_beat_index)

func intentar_beat(tipo_tambor, diff, beat_index):
	# Evitar golpear el mismo beat dos veces (spamming)
	if beat_index == last_hit_beat_index:
		return 
		
	if diff <= tolerance:
		# ¡ÉXITO!
		print("¡Perfecto! Beat: ", beat_index, " - ", tipo_tambor)
		last_hit_beat_index = beat_index # Marcamos este beat como usado
		emit_signal("beat_acertado", tipo_tambor) # Para animar la UI
		register_input(tipo_tambor)
	else:
		# ¡FALLO!
		print("¡Fallo! Fuera de ritmo (Diff: ", diff, ")")
		reset_combo()

func register_input(drum_name):
	command_buffer.append(drum_name)
	
	# Si tenemos 4 inputs, verificamos si es una orden válida
	if command_buffer.size() >= 4:
		check_command()

func check_command():
	# Tomamos solo los últimos 4 comandos
	var ultimos_4 = command_buffer.slice(-4)
	
	match ultimos_4:
		["Pata", "Pata", "Pata", "Pon"]:
			print("ORDEN: MARCHAR")
			emit_signal("orden_marchar")
		["Pon", "Pon", "Pata", "Pon"]:
			print("ORDEN: ATACAR")
			emit_signal("orden_atacar")
		["Chaka", "Chaka", "Pata", "Pon"]:
			print("ORDEN: DEFENDER")
			emit_signal("orden_defenda")
		_:
			# Si llegamos a 4 y no coincide con nada
			print("Combo desconocido -> Tropiezo")
			emit_signal("orden_fallida")
	
	# IMPORTANTE: Limpiamos el buffer tras ejecutar (o fallar) la orden
	command_buffer.clear()

func reset_combo():
	# Romper el combo (feedback visual de error aquí sería ideal)
	print("--- COMBO ROTO ---")
	emit_signal("orden_fallida")
	command_buffer.clear()

func _on_nuevo_beat(_beat_index):
	# 1. En el momento exacto del beat, lo hacemos VISIBLE
	$Panel.visible = true
	
	# 2. Creamos un temporizador (Tween) para apagarlo
	var tween = create_tween()
	
	# Esperamos exactamente el tiempo de tolerancia (ej. 0.15 seg)
	tween.tween_interval(tolerance)
	
	# Pasado ese tiempo, lo hacemos INVISIBLE
	tween.tween_callback(func(): $Panel.visible = false)
