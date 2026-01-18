extends RigidBody2D

@onready var cuerda: Line2D = $Line2D
@onready var player_join: Marker2D = $Player_join
@onready var ball_join: RigidBody2D = $RigidBody2D
@export var fuerza_movimiento = 3000.0

var knockback_actual: Vector2 = Vector2.ZERO 
@export var friccion_knockback: float = 10.0

const SPEED = 200.0

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _process(_delta: float) -> void:
	cuerda.clear_points()

	cuerda.add_point(player_join.position)
	cuerda.add_point(ball_join.position)


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return 
	
	var direction := Input.get_vector("left", "right","up","down")
	if direction != Vector2.ZERO:
		apply_central_force(direction * fuerza_movimiento)
