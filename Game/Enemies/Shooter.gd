extends CharacterBody2D

class_name Shooter






























































































@export var move_speed: float = 80.0
@export var gravity: float = 1800.0
@export var terminal_velocity: float = 500.0
@export var attack_cooldown: float = 2.0
@export var attack_damage: int = 1
@export var knockback_distance: float = 60.0
@export var screen_shake_amount: float = 8.0
@export var screen_shake_duration: float = 0.5
@export var max_health: int = 5

@onready var contact_damage_area: Area2D = $ContactDamage
@onready var visual: Node2D = $Visual
@onready var animated_sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

var player: Player
var base_visual_scale: Vector2 = Vector2.ONE
var facing_direction: float = 1.0
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var health: int = 5

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	health = max_health
	base_visual_scale = visual.scale
	_setup_sprite_frames()
	contact_damage_area.body_entered.connect(_on_contact_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_play_movement_animation()

func _physics_process(delta: float) -> void:
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer = maxf(attack_cooldown_timer - delta, 0.0)
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		return
	
	var dx: float = player.global_position.x - global_position.x
	var direction_x: float = 0.0
	if dx > 0.0:
		direction_x = 1.0
	elif dx < 0.0:
		direction_x = -1.0
	if direction_x != 0.0:
		velocity.x = direction_x * move_speed
		visual.scale.x = base_visual_scale.x * direction_x
		facing_direction = direction_x
	else:
		velocity.x = 0.0
	
	if is_attacking:
		velocity.x = 0.0
	else:
		_play_movement_animation()
	
	velocity.y = clamp(velocity.y + gravity * delta, -INF, terminal_velocity)
	move_and_slide()
	_check_contact_attack_from_collisions()

func _on_contact_body_entered(body: Node) -> void:
	if body is Player:
		_try_contact_attack(body)

func _check_contact_attack_from_collisions() -> void:
	var count: int = get_slide_collision_count()
	if count == 0:
		return
	for i in range(count):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Player:
			_try_contact_attack(collider)
			return

func _try_contact_attack(target: Player) -> void:
	if attack_cooldown_timer > 0.0:
		return
	target.take_damage(attack_damage)
	target.apply_knockback(global_position, knockback_distance)
	target.shake_camera(screen_shake_amount, screen_shake_duration)
	attack_cooldown_timer = attack_cooldown
	_start_attack()

func _start_attack() -> void:
	is_attacking = true
	animated_sprite.play("attack")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		_play_movement_animation()

func _play_movement_animation() -> void:
	if abs(velocity.x) > 0.1:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func take_damage(amount: int = 1) -> void:
	if amount <= 0:
		return
	health = max(health - amount, 0)
	if health <= 0:
		queue_free()

func _setup_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	_add_animation(frames, "idle", "res://Resources/Enemies/DeadRevolver/shooter/idle/shooter_idle_", 7, 8.0, true)
	_add_animation(frames, "run", "res://Resources/Enemies/DeadRevolver/shooter/run/shooter_run_", 6, 10.0, true)
	_add_animation(frames, "attack", "res://Resources/Enemies/DeadRevolver/shooter/attack/shooter_attack_", 6, 12.0, false)
	animated_sprite.sprite_frames = frames

func _add_animation(frames: SpriteFrames, name: String, prefix: String, count: int, fps: float, looped: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, looped)
	for i in range(1, count + 1):
		var path := "%s%02d.png" % [prefix, i]
		var tex := load(path)
		if tex is Texture2D:
			frames.add_frame(name, tex)
