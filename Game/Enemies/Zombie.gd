# res://game/enemies/zombie.gd

extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var max_health: int = 5
var health: int = 5

func _ready():
	add_to_group("enemy")
	health = max_health
	animation_player.play("idle")

func take_damage(amount: int = 1) -> void:
	if amount <= 0:
		return
	health = max(health - amount, 0)
	if health <= 0:
		queue_free()
