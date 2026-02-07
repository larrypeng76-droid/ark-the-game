# res://Game/Player/player_bullet.gd

extends Area2D

class_name PlayerBullet

@export var speed: float = 300.0
@export var damage: int = 1
@export var max_lifetime: float = 2.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0

func _ready() -> void:
	lifetime = max_lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(direction: float, bullet_speed: float) -> void:
	var dir_x: float = direction
	if dir_x == 0.0:
		dir_x = 1.0
	var sign_dir: float = 1.0 if dir_x > 0.0 else -1.0
	speed = bullet_speed
	velocity = Vector2(sign_dir * speed, 0.0)
	var scale_x: float = absf(scale.x)
	scale.x = scale_x if sign_dir > 0.0 else -scale_x

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("hit"):
		area.hit(damage, self)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		var hurtbox: Area2D = body.get_node_or_null("HurtBox")
		if hurtbox and hurtbox.has_method("hit"):
			hurtbox.hit(damage, self)
	queue_free()
