extends RigidBody2D

# Ajusta esto para que el golpe sea más fuerte o débil
@export var fuerza_impacto_bola: float = 1.5 

func _integrate_forces(state):
	# Recorremos los contactos físicos reales de este frame
	for i in state.get_contact_count():
		var collider = state.get_contact_collider_object(i)
		
		# Verificamos si chocamos con un CharacterBody2D (el player)
		if collider is CharacterBody2D:
			# Obtenemos la velocidad actual de la bola
			var mi_velocidad = state.linear_velocity
			
			# Solo empujamos si la bola va rápido (para evitar empujes fantasma al estar quietos)
			if mi_velocidad.length() > 50.0:
				# Calculamos la dirección del golpe (hacia donde va la bola)
				var direccion_golpe = mi_velocidad.normalized()
				var fuerza = mi_velocidad.length() * fuerza_impacto_bola
				
				# Llamamos a la función de tu player
				if collider.has_method("recibir_knockback"):
					collider.recibir_knockback(direccion_golpe, fuerza)
