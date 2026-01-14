extends RigidBody2D # O RigidBody3D

@export var fuerza_empuje: float = 500.0

func _on_body_entered(body: Node):
	# Verificamos si el cuerpo con el que chocamos tiene la función para recibir daño/empuje
	if body.has_method("recibir_knockback") and body != self:
		print("2")
		
		var direccion = (body.global_position - global_position).normalized()
		
		# Llamamos a la función en la víctima
		body.recibir_knockback(direccion, fuerza_empuje)


func recibir_knockback(direccion: Vector2, fuerza: float):
	# En RigidBodies es mucho más fácil, solo aplicamos un impulso central
	apply_central_impulse(direccion * fuerza)
