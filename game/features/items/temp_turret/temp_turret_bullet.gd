extends Area2D

@export_range(80.0, 2400.0, 10.0) var speed: float = 620.0
@export_range(0.1, 5.0, 0.1) var max_lifetime_sec: float = 1.8
@export_range(1, 99, 1) var damage: int = 1

var _velocity: Vector2 = Vector2.ZERO
var _remaining_lifetime_sec: float = 0.0


func _ready() -> void:
	_remaining_lifetime_sec = max_lifetime_sec
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func setup_direction(direction: Vector2, bullet_speed: float, bullet_damage: int = 1) -> void:
	speed = bullet_speed
	damage = bullet_damage
	var move_direction: Vector2 = direction
	if move_direction.length_squared() <= 0.000001:
		move_direction = Vector2.RIGHT
	_velocity = move_direction.normalized() * speed
	rotation = _velocity.angle()


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_remaining_lifetime_sec -= delta
	if _remaining_lifetime_sec <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage, self)
	queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()
