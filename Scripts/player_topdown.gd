extends CharacterBody2D

@onready var cuerda: Line2D = $Line2D
@onready var player_join: Marker2D = $Player_join
@onready var ball_join: RigidBody2D = $RigidBody2D

var knockback_actual: Vector2 = Vector2.ZERO 
@export var friccion_knockback: float = 10.0

const SPEED = 200.0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _process(_delta: float) -> void:
	cuerda.clear_points()

	cuerda.add_point(player_join.position)
	cuerda.add_point(ball_join.position)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()

		if body is RigidBody2D:
			var push_dir = -collision.get_normal()
			var push_force = velocity.length() * 0.8
			body.apply_central_impulse(push_dir * push_force)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return 
	
	if knockback_actual.length() > 0:
		knockback_actual = knockback_actual.lerp(Vector2.ZERO, friccion_knockback * delta)
		velocity += knockback_actual
	
	var direction := Input.get_vector("left", "right","up","down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		
	move_and_slide()




func recibir_knockback(direccion: Vector2, fuerza: float):
	# Asignamos el vector de empuje
	knockback_actual = direccion * fuerza
	
