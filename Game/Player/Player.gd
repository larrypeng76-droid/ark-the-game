# res://Game/Player/Player.gd

extends CharacterBody2D

class_name Player

const DeathScreenScene := preload("res://Core/UI/DeathScreen.tscn")
const PlayerBulletScene := preload("res://Game/Player/player_bullet.tscn")

@export_group("World")
@export var world_gravity: float = 1800
@export var world_terminal_velocity: float = 500

@export_group("Player Movement")
@export var max_speed: float = 160.0
@export var max_speed_crouched: float = 100.0
@export var ground_acceleration: int = 1500
@export var ground_deacceleration: int = 2000
@export var air_acceleration: int = 800
@export var air_deacceleration: int = 1000

@export_group("Player Jumping")
@export var jump_force: float = -400
@export var max_jumps: int = 1

@export_group("Player Combat")
@export var bullet_speed: float = 300.0
@export var melee_range: float = 20.0

@export_group("Player Health")
@export var max_health: int = 10

@export_group("Player Collision")
@export var top_bounce_distance: float = 40.0
@export var top_bounce_cooldown: float = 0.2

@export_group("Player Feel")
@export var hard_land_run_time: float = 0.8
@export var hard_land_fall_time: float = 0.6
@export var land_run_time: float = 0.2
@export var coyote_time : float = 0.1
@export var buffer_time : float = 0.12
@export var coyote_timer : float = 0.0
@export var buffer_timer : float = -1.0

var jumps: int = 0
var health: int = 10
var is_dead: bool = false
var weapon_drawn: bool = false
var is_crouched: bool = false
var is_attacking: bool = false
var jump_pressed: bool = false

var direction :float = 0.0
var facing_direction: int = 1 # 1 is right, -1 is left
var top_bounce_cooldown_timer: float = 0.0

signal is_crouched_changed(new_value: bool)
signal is_weapon_drawn_changed(new_value: bool)

@onready var state_machine: PlayerStateMachine = $PlayerStateMachine
@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D

@onready var collision_shape_standing: CollisionShape2D = $CollisionShapeStanding
@onready var collision_shape_crouched: CollisionShape2D = $CollisionShapeCrouched
@onready var collision_ray_cast: RayCast2D = $CanStandRayCast 

@onready var debug_state: Label = $CanvasLayer/MarginContainer/VBoxContainer/State
@onready var debug_max_speed: Label = $CanvasLayer/MarginContainer/VBoxContainer/MaxSpeed
@onready var debug_speed: Label = $CanvasLayer/MarginContainer/VBoxContainer/Speed
@onready var debug_weapon_drawn: Label = $CanvasLayer/MarginContainer/VBoxContainer/WeaponDrawn
@onready var debug_jumps: Label = $CanvasLayer/MarginContainer/VBoxContainer/Jumps
@onready var debug_is_crouched: Label = $CanvasLayer/MarginContainer/VBoxContainer/IsCrouched
@onready var health_hearts: Label = $HUD/MarginContainer/Hearts

enum collision_shapes { STANDING, CROUCHED }

var active_collision_shape := collision_shapes.STANDING
var camera_shake_tween: Tween
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

const ENEMY_LAYER_MASK: int = 1 << 1

func _ready():
	add_to_group("player")
	health = max_health
	rng.randomize()
	camera.zoom = Vector2(1, 1)
	_setup_input_actions()
	
	animation_player.animation_finished.connect(_on_animation_finished)
	is_crouched_changed.connect(_on_is_crouched_changed)
	is_weapon_drawn_changed.connect(_on_weapon_drawn_changed)
	
	set_collision_shape(active_collision_shape)
	debug_max_speed.text = "MaxSpeed: +/- %s" % str(max_speed)
	state_machine.change_state("IdleState")
	update_health_ui()
	
# Signals	
func _on_animation_finished(animation: StringName) -> void:
	if state_machine.current_state:
		state_machine.current_state.on_animation_finished(animation)

func _on_is_crouched_changed(new_value: bool) -> void:
	if state_machine.current_state:
		state_machine.current_state.on_is_crouched_changed(new_value)

func _on_weapon_drawn_changed(new_value: bool) -> void:
	if state_machine.current_state:
		state_machine.current_state.on_weapon_drawn_changed(new_value)


func _input(_event: InputEvent):
	if is_dead:
		return
	
	if Input.is_action_just_pressed("attackShoot") and not is_attacking:
		if _is_enemy_in_melee_range():
			state_machine.change_state("WeaponAttackJabState")
		else:
			_fire_bullet()
		return
	
	if weapon_drawn and not is_attacking and Input.is_action_just_pressed("attackJab"):
		state_machine.change_state("WeaponAttackJabState")
		return
		
	if weapon_drawn and not is_attacking and Input.is_action_just_pressed("attackOverhead"):
		state_machine.change_state("WeaponAttackOverheadState")
		return
	
	direction = Input.get_axis("moveLeft", "moveRight")
	
	if direction != 0.0:
		facing_direction = sign(direction)
		visual.scale.x = facing_direction
		
	if Input.is_action_just_pressed("escape"):
		var transition_manager := TransitionManager.new()
		get_tree().root.add_child(transition_manager)
		await transition_manager.change_scene_with_fade("res://Game/MainMenu.tscn")
	
	if Input.is_action_just_pressed("crouch"):
		var new_value := !is_crouched

		if new_value == false and can_stand() == false:
			print_debug("Cannot stand, collision block")
			return
		
		if new_value != is_crouched:
			is_crouched = new_value
			is_crouched_changed.emit(is_crouched)
			print_debug("Is crouched set to " + str(is_crouched))
		
	if Input.is_action_just_pressed("toggleWeapon"):
		var new_value := !weapon_drawn
		
		if new_value != weapon_drawn:
			weapon_drawn = new_value
			is_weapon_drawn_changed.emit(weapon_drawn)
			print_debug("Weapon drawn set " + str(weapon_drawn))
			
	jump_pressed = Input.is_action_just_pressed("jump")
	
func _process(delta: float):
	if is_dead:
		return

	state_machine.process_update(delta)
	debug_weapon_drawn.text = "WeaponDrawn: %s" % str(weapon_drawn)
	debug_jumps.text = "Jumps: %d" % jumps
	debug_is_crouched.text = "IsCrouched: %s" % str(is_crouched)

func _physics_process(delta: float):
	if is_dead:
		return
	if top_bounce_cooldown_timer > 0.0:
		top_bounce_cooldown_timer = maxf(top_bounce_cooldown_timer - delta, 0.0)
	
	tick_jump_timers(delta)
	
	if not is_on_floor():
		velocity.y = clamp(velocity.y + world_gravity * delta, -INF, world_terminal_velocity)
	
	state_machine.physics_update(delta)
	var pre_slide_velocity_y: float = velocity.y
	move_and_slide()
	_check_top_enemy_bounce(pre_slide_velocity_y)
	
func force_stand() -> void:
	if is_crouched and can_stand():
		is_crouched = false
		is_crouched_changed.emit(false)
		print_debug("Force standing state")
		
func sheave_weapon() -> void:
	if weapon_drawn == true:
		weapon_drawn = false
		print_debug("Weapon sheaved")
	
func play_animation(animation: String, weapon_version: bool = false):
	if weapon_version == true and weapon_drawn == true:
		animation_player.play("%s-weapon" % animation)
	else:
		animation_player.play(animation)

func _setup_input_actions() -> void:
	if not InputMap.has_action("attackShoot"):
		InputMap.add_action("attackShoot")
		var enter_event := InputEventKey.new()
		enter_event.keycode = KEY_ENTER
		enter_event.physical_keycode = KEY_ENTER
		InputMap.action_add_event("attackShoot", enter_event)
		var kp_enter_event := InputEventKey.new()
		kp_enter_event.keycode = KEY_KP_ENTER
		kp_enter_event.physical_keycode = KEY_KP_ENTER
		InputMap.action_add_event("attackShoot", kp_enter_event)

func _fire_bullet() -> void:
	var bullet := PlayerBulletScene.instantiate()
	var direction: float = facing_direction
	if direction == 0.0:
		direction = 1.0
	bullet.global_position = global_position + Vector2(12 * direction, -12)
	if bullet.has_method("setup"):
		bullet.setup(direction, bullet_speed)
	get_tree().current_scene.add_child(bullet)

func _is_enemy_in_melee_range() -> bool:
	var enemies: Array = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return false
	var range_sq: float = melee_range * melee_range
	for enemy in enemies:
		if enemy is Node2D:
			var enemy_node: Node2D = enemy
			var dist_sq: float = enemy_node.global_position.distance_squared_to(global_position)
			if dist_sq <= range_sq:
				return true
	return false
		
func queue_jump():
	if jumps < max_jumps:
		buffer_timer = buffer_time

func tick_jump_timers(delta):
	if !is_on_floor(): 
		coyote_timer = max(coyote_timer - delta, -1.0)
	else:
		coyote_timer = coyote_time
		jumps = 0
		
	if buffer_timer >= 0.0:
		buffer_timer -= delta
		if can_jump_now():
			do_jump()

func can_jump_now() -> bool:
	return (coyote_timer > 0.0 or jumps < max_jumps) and buffer_timer >= 0.0

func do_jump():
	force_stand()
	
	jumps += 1
	velocity.y = jump_force
	buffer_timer = -1.0
	
func apply_acceleration_in_x_on_ground(_direction: float, delta: float) -> float:
	var target_speed = max_speed * _direction
	var player_velocity = move_toward(velocity.x, target_speed, ground_acceleration * delta)
	debug_speed.text = "Speed %s " % str(roundf(player_velocity))
	
	return player_velocity
	
func apply_acceleration_in_x_on_ground_crouched(_direction: float, delta: float) -> float:
	var target_speed = max_speed_crouched * _direction
	var player_velocity = move_toward(velocity.x, target_speed, ground_acceleration * delta)
	debug_speed.text = "Speed %s " % str(roundf(player_velocity))
	
	return player_velocity
	
func apply_acceleration_in_x_in_air(_direction: float, delta: float) -> float:
	var target_speed = max_speed * _direction
	var player_velocity = move_toward(velocity.x, target_speed, air_acceleration * delta)
	debug_speed.text = "Speed %s " % str(roundf(player_velocity))
	
	return player_velocity
	
func apply_deacceleration_in_x_on_ground(delta: float) -> float:
	var player_velocity = move_toward(velocity.x, 0.0, ground_deacceleration * delta)
	debug_speed.text = "Speed %s " % str(roundf(player_velocity))
	
	return player_velocity
	
func apply_deacceleration_in_x_in_air(delta: float) -> float:
	var player_velocity = move_toward(velocity.x, 0.0, ground_deacceleration * delta)
	debug_speed.text = "Speed %s " % str(roundf(player_velocity))
	
	return player_velocity
	
func can_stand() -> bool:
	if (collision_ray_cast.is_colliding()):
		return false
		
	return true;
	
func set_collision_shape(shape) -> void:
	
	if shape == active_collision_shape:
		return
	
	match shape:
		collision_shapes.STANDING:
			collision_shape_standing.set_deferred("disabled", false)
			collision_shape_crouched.set_deferred("disabled", true)
		collision_shapes.CROUCHED:
			collision_shape_standing.set_deferred("disabled", true)
			collision_shape_crouched.set_deferred("disabled", false)
			
	active_collision_shape = shape

func apply_knockback(from_position: Vector2, distance: float) -> void:
	if distance <= 0.0:
		return
	var direction: float = 0.0
	if global_position.x > from_position.x:
		direction = 1.0
	elif global_position.x < from_position.x:
		direction = -1.0
	else:
		direction = 1.0
	var motion: Vector2 = Vector2(direction * distance, 0.0)
	move_and_collide(motion)

func apply_random_knockback(distance: float) -> void:
	if distance <= 0.0:
		return
	var direction: float = -1.0 if rng.randf() < 0.5 else 1.0
	var motion: Vector2 = Vector2(direction * distance, 0.0)
	move_and_collide(motion)

func _check_top_enemy_bounce(pre_slide_velocity_y: float) -> void:
	if top_bounce_cooldown_timer > 0.0:
		return
	if pre_slide_velocity_y <= 0.0:
		return
	var count: int = get_slide_collision_count()
	if count == 0:
		return
	for i in range(count):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is CollisionObject2D and (collider.collision_layer & ENEMY_LAYER_MASK) != 0:
			var normal: Vector2 = collision.get_normal()
			if normal.y < -0.7:
				apply_random_knockback(top_bounce_distance)
				top_bounce_cooldown_timer = top_bounce_cooldown
				return

func shake_camera(amount: float = 4.0, duration: float = 0.12) -> void:
	if not camera:
		return
	if camera_shake_tween:
		camera_shake_tween.kill()
	var original_offset: Vector2 = camera.offset
	camera_shake_tween = create_tween()
	camera_shake_tween.tween_property(camera, "offset", Vector2(0.0, -amount), duration * 0.25)
	camera_shake_tween.tween_property(camera, "offset", Vector2(0.0, amount), duration * 0.25)
	camera_shake_tween.tween_property(camera, "offset", Vector2(0.0, -amount * 0.5), duration * 0.25)
	camera_shake_tween.tween_property(camera, "offset", original_offset, duration * 0.25)

func take_damage(amount: int = 1) -> void:
	if is_dead or amount <= 0:
		return
		
	health = clampi(health - amount, 0, max_health)
	update_health_ui()
	
	if health <= 0:
		die()

func update_health_ui() -> void:
	if not health_hearts:
		return
		
	var full := "♥".repeat(health)
	var empty := "♡".repeat(max_health - health)
	health_hearts.text = "%s%s" % [full, empty]

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	
	var death_screen := DeathScreenScene.instantiate()
	get_tree().current_scene.add_child(death_screen)
	get_tree().paused = true
