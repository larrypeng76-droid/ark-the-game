# res://game/player/player_bullet.gd

extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var max_lifetime: float = 2.0
@export var guided_stop_distance: float = 6.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0
var _aim_global_position: Callable
var _is_guided: bool = false

func _ready() -> void:
	lifetime = max_lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup_guided(aim_global_position: Callable, direction: Vector2, bullet_speed: float) -> void:
	speed = bullet_speed
	_aim_global_position = aim_global_position
	_is_guided = aim_global_position.is_valid()
	_set_velocity_from_direction(direction)


func setup(direction: float, bullet_speed: float) -> void:
	var dir_x: float = direction
	if dir_x == 0.0:
		dir_x = 1.0
	var sign_dir: float = 1.0 if dir_x > 0.0 else -1.0
	setup_direction(Vector2(sign_dir, 0.0), bullet_speed)
	var scale_x: float = absf(scale.x)
	scale.x = scale_x if sign_dir > 0.0 else -scale_x


func setup_direction(direction: Vector2, bullet_speed: float) -> void:
	speed = bullet_speed
	_is_guided = false
	_aim_global_position = Callable()
	_set_velocity_from_direction(direction)


func _set_velocity_from_direction(direction: Vector2) -> void:
	var dir: Vector2 = direction
	if dir.length_squared() <= 0.000001:
		dir = Vector2.RIGHT
	velocity = dir.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if _is_guided and not _aim_global_position.is_valid():
		_is_guided = false

	if _is_guided:
		var target: Vector2
		var result: Variant = _aim_global_position.call()
		if result is Vector2:
			target = result
			var to_target: Vector2 = target - global_position
			if to_target.length() <= guided_stop_distance:
				_is_guided = false
			else:
				velocity = to_target.normalized() * speed
				rotation = velocity.angle()
		else:
			_is_guided = false

	global_position += velocity * delta
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
