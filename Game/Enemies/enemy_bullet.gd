extends Node2D

@export var speed: float = 220.0
@export var damage: int = 1
@export var max_lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0

@onready var damage_area: Area2D = $DamageArea
@onready var terrain_sensor: Area2D = $TerrainSensor

func _ready() -> void:
	lifetime = max_lifetime
	damage_area.area_entered.connect(_on_damage_area_entered)
	terrain_sensor.body_entered.connect(_on_terrain_body_entered)

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

func _on_damage_area_entered(area: Area2D) -> void:
	if area and area.has_method("hit"):
		area.hit(damage, self)
	queue_free()

func _on_terrain_body_entered(_body: Node) -> void:
	queue_free()
