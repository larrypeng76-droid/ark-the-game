extends Node2D

@export var enemy_scene: PackedScene = preload("res://game/enemies/zombie.tscn")
@export var spawn_interval_seconds: float = 5.0
@export var spawn_position: Vector2 = Vector2(250.0, 250.0)

@onready var spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	if enemy is Node2D:
		(enemy as Node2D).global_position = spawn_position
	add_child(enemy)
