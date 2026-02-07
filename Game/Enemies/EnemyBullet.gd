extends Area2D

class_name EnemyBullet

@export var speed: float = 220.0
@export var damage: int = 1
@export var max_lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0

func _ready() -> void:
	lifetime = max_lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))

func setup(direction: Vector2, bullet_speed: float, bullet_damage: int) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	velocity = direction.normalized() * bullet_speed
	speed = bullet_speed
	damage = bullet_damage

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
	queue_free()
