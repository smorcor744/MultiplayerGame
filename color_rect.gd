extends ColorRect

func _ready():

	modulate.a = 0.0

func _on_nuevo_beat(beat_num):
	# Usamos Tween para hacer un parpadeo suave
	var tween = create_tween()
	
	# 1. Aparece instantáneamente (o muy rápido)
	tween.tween_property(self, "modulate:a", 0.3, 0.05) 
	# (El 0.3 es la intensidad, no lo pongas a 1.0 o cegarás al jugador)
	
	# 2. Desaparece suavemente
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
