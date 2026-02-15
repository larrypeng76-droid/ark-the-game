# res://game/player/player.gd

extends CharacterBody2D

const DeathScreenScene := preload("res://core/ui/death_screen.tscn")
const PlayerCombatLogic := preload("res://game/player/player_combat_logic.gd")
const PlayerHealthLogic := preload("res://game/player/player_health_logic.gd")
const DigPreviewEffectScript := preload("res://game/player/dig_preview_effect.gd")
const SurfaceDarknessOverlayShader := preload("res://game/player/surface_darkness_overlay.gdshader")
const AxePickupScene := preload("res://game/features/items/axe/axe.tscn")

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
@export_range(1.0, 30.0, 1.0) var auto_fire_shots_per_second: float = 8.0
@export_range(1, 999, 1) var bullets_per_magazine: int = 100
@export_range(0, 99, 1) var starting_magazines: int = 3
@export_range(0.1, 10.0, 0.1) var reload_duration_seconds: float = 3.0

@export_group("Pickaxe Dig")
@export_range(1.0, 256.0, 1.0) var dig_radius: float = 2.0

@export_group("Auto Pickup")
@export_range(1.0, 64.0, 1.0) var auto_pickup_stop_distance: float = 1.0
@export_range(0.0, 1.0, 0.01) var auto_pickup_jump_delay: float = 0.18

@export_group("Surface Darkness")
@export_range(0.0, 1.0, 0.01) var surface_darkness_alpha: float = 0.9
@export_range(1.0, 300.0, 1.0) var surface_clear_radius: float = 120.0
@export_range(0.0, 80.0, 1.0) var surface_edge_fade: float = 14.0
@export_range(0.0, 2000.0, 1.0) var surface_darkness_start_depth: float = 80.0
@export_range(1.0, 2000.0, 1.0) var surface_darkness_end_depth: float = 200.0

const ORANGE_DIG_BOX_SIZE: float = 50.0
const ORANGE_DIG_BOX_HALF_SIZE: float = ORANGE_DIG_BOX_SIZE * 0.5

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
var _auto_fire_cooldown: float = 0.0
var _is_shoot_held: bool = false
var ammo_in_mag: int = 0
var spare_magazines: int = 0
var _is_reloading: bool = false
var _reload_time_left: float = 0.0
var pickaxe_equipped: bool = false
var axe_equipped: bool = false
var _diggable_ground: Node
var _auto_pickup_target: Node2D
var _auto_pickup_stuck_time: float = 0.0

signal is_crouched_changed(new_value: bool)
signal is_weapon_drawn_changed(new_value: bool)
signal ammo_state_changed(ammo_in_mag: int, spare_mags: int, is_reloading: bool, reload_time_left: float)

var state_machine

var health_logic: RefCounted
var combat_logic: RefCounted

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

@onready var crosshair_layer: CanvasLayer = $CrosshairLayer
@onready var aim_crosshair: Node2D = $CrosshairLayer/AimCrosshair

var inventory_ui: CanvasLayer
var _initial_pickaxe_granted: bool = false
var _initial_axe_spawned: bool = false

const INVENTORY_UI_GROUP_NAME := "inventory_ui"
const INVENTORY_UI_SETUP_MAX_RETRIES: int = 10
const DIGGABLE_GROUND_GROUP_NAME := "diggable_ground"

enum collision_shapes { STANDING, CROUCHED }

var active_collision_shape := collision_shapes.STANDING
var camera_shake_tween: Tween
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _opaque_centroid_cache: Dictionary = {}
var _orange_centroid_cache: Dictionary = {}
var _purple_centroid_cache: Dictionary = {}

var _equipped_pickaxe_sprite: Sprite2D
var _surface_darkness_overlay: ColorRect
var _surface_darkness_material: ShaderMaterial

const ENEMY_LAYER_MASK: int = 1 << 1

func _ready():
	add_to_group("player")
	state_machine = $PlayerStateMachine
	health = max_health
	health_logic = PlayerHealthLogic.new()
	combat_logic = PlayerCombatLogic.new()
	rng.randomize()
	# Slight zoom-out (make the view a bit wider).
	camera.zoom = Vector2(1.15, 1.15)
	_init_ammo_state()
	_setup_equipped_pickaxe_visual()
	_setup_surface_darkness_overlay()
	_update_crosshair_visibility()
	
	animation_player.animation_finished.connect(_on_animation_finished)
	is_crouched_changed.connect(_on_is_crouched_changed)
	is_weapon_drawn_changed.connect(_on_weapon_drawn_changed)
	
	set_collision_shape(active_collision_shape)
	debug_max_speed.text = "MaxSpeed: +/- %s" % str(max_speed)
	state_machine.connect("state_changed", Callable(self, "_on_state_changed"))
	state_machine.call("change_state", "IdleState")
	update_health_ui()
	call_deferred("_setup_inventory_ui")
	call_deferred("_setup_item_pickups")
	_emit_ammo_state_changed()
	if not get_tree().node_added.is_connected(Callable(self, "_on_tree_node_added")):
		get_tree().node_added.connect(Callable(self, "_on_tree_node_added"))


func _init_ammo_state() -> void:
	ammo_in_mag = max(bullets_per_magazine, 0)
	# We treat "starting_magazines" as total magazines, including the one currently loaded.
	spare_magazines = maxi(starting_magazines - 1, 0)
	_is_reloading = false
	_reload_time_left = 0.0


func get_ammo_state() -> Dictionary:
	return {
		"ammo_in_mag": ammo_in_mag,
		"spare_mags": spare_magazines,
		"is_reloading": _is_reloading,
		"reload_time_left": _reload_time_left,
	}


func _emit_ammo_state_changed() -> void:
	ammo_state_changed.emit(ammo_in_mag, spare_magazines, _is_reloading, _reload_time_left)


func _setup_equipped_pickaxe_visual() -> void:
	_equipped_pickaxe_sprite = Sprite2D.new()
	_equipped_pickaxe_sprite.name = "EquippedPickaxe"
	_equipped_pickaxe_sprite.texture = _create_pickaxe_texture()
	_equipped_pickaxe_sprite.centered = true
	_equipped_pickaxe_sprite.visible = false
	_equipped_pickaxe_sprite.z_index = 3
	visual.add_child(_equipped_pickaxe_sprite)


func _create_pickaxe_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))

	for y in range(4, 13):
		for x in range(7, 9):
			img.set_pixel(x, y, Color(0.46, 0.24, 0.11, 1.0))
	for y in range(2, 6):
		for x in range(3, 13):
			img.set_pixel(x, y, Color(0.72, 0.72, 0.78, 1.0))

	return ImageTexture.create_from_image(img)

func _on_state_changed(new_state_name: String) -> void:
	debug_state.text = "State: %s" % new_state_name
	
# Signals	
func _on_animation_finished(animation: StringName) -> void:
	var current_state = state_machine.get("current_state")
	if current_state and current_state.has_method("on_animation_finished"):
		current_state.call("on_animation_finished", animation)

func _on_is_crouched_changed(new_value: bool) -> void:
	var current_state = state_machine.get("current_state")
	if current_state and current_state.has_method("on_is_crouched_changed"):
		current_state.call("on_is_crouched_changed", new_value)

func _on_weapon_drawn_changed(new_value: bool) -> void:
	var current_state = state_machine.get("current_state")
	if current_state and current_state.has_method("on_weapon_drawn_changed"):
		current_state.call("on_weapon_drawn_changed", new_value)


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if pickaxe_equipped:
		if event is InputEventMouseButton:
			var dig_mouse_button: InputEventMouseButton = event
			if dig_mouse_button.button_index == MOUSE_BUTTON_LEFT:
				_is_shoot_held = false
				if dig_mouse_button.pressed:
					_try_dig_ground_at_cursor_if_allowed()
				return

	if axe_equipped:
		if event is InputEventMouseButton:
			var axe_mouse_button: InputEventMouseButton = event
			if axe_mouse_button.button_index == MOUSE_BUTTON_LEFT:
				_is_shoot_held = false
				if axe_mouse_button.pressed:
					_try_chop_trees_at_cursor_if_allowed()
				return

	var shoot_pressed: bool = Input.is_action_just_pressed("attackShoot")
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_is_shoot_held = mouse_button.pressed
			if mouse_button.pressed:
				shoot_pressed = true

	if shoot_pressed and not is_attacking:
		if _is_enemy_in_melee_range():
			state_machine.call("change_state", "WeaponAttackJabState")
		else:
			if _try_fire_bullet():
				_auto_fire_cooldown = 1.0 / auto_fire_shots_per_second
		return
	
	if weapon_drawn and not is_attacking and Input.is_action_just_pressed("attackJab"):
		state_machine.call("change_state", "WeaponAttackJabState")
		return
		
	if weapon_drawn and not is_attacking and Input.is_action_just_pressed("attackOverhead"):
		state_machine.call("change_state", "WeaponAttackOverheadState")
		return
	
	direction = Input.get_axis("moveLeft", "moveRight")
	
	if direction != 0.0:
		var dir_sign: int = 1 if direction > 0.0 else -1
		facing_direction = dir_sign
		visual.scale.x = facing_direction
		
		if Input.is_action_just_pressed("escape"):
			await GameFlow.go_to_main_menu()
	
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

	_update_auto_pickup_movement()
	_update_crosshair_visibility()
	state_machine.call("process_update", delta)
	debug_weapon_drawn.text = "WeaponDrawn: %s" % str(weapon_drawn)
	debug_jumps.text = "Jumps: %d" % jumps
	debug_is_crouched.text = "IsCrouched: %s" % str(is_crouched)
	_update_equipped_pickaxe_visual()
	_update_surface_darkness_overlay()
	_update_reload(delta)
	_update_auto_fire(delta)


func _setup_surface_darkness_overlay() -> void:
	if crosshair_layer == null:
		return
	_surface_darkness_overlay = ColorRect.new()
	_surface_darkness_overlay.name = "SurfaceDarknessOverlay"
	_surface_darkness_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_surface_darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface_darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_surface_darkness_overlay.offset_left = 0.0
	_surface_darkness_overlay.offset_top = 0.0
	_surface_darkness_overlay.offset_right = 0.0
	_surface_darkness_overlay.offset_bottom = 0.0

	_surface_darkness_material = ShaderMaterial.new()
	_surface_darkness_material.shader = SurfaceDarknessOverlayShader
	_surface_darkness_material.set_shader_parameter("clear_radius", surface_clear_radius)
	_surface_darkness_material.set_shader_parameter("edge_fade", surface_edge_fade)
	_surface_darkness_material.set_shader_parameter("darkness_alpha", surface_darkness_alpha)
	_surface_darkness_overlay.material = _surface_darkness_material
	_surface_darkness_overlay.visible = false
	crosshair_layer.add_child(_surface_darkness_overlay)


func _update_surface_darkness_overlay() -> void:
	if _surface_darkness_overlay == null or _surface_darkness_material == null:
		return

	var grass_y_variant: Variant = _get_grass_surface_world_y()
	if not (grass_y_variant is float):
		_surface_darkness_overlay.visible = false
		return
	var grass_y: float = grass_y_variant as float
	var depth_from_surface: float = global_position.y - grass_y
	var should_darken: bool = depth_from_surface > surface_darkness_start_depth
	_surface_darkness_overlay.visible = should_darken
	if not should_darken:
		return

	var depth_span: float = maxf(surface_darkness_end_depth - surface_darkness_start_depth, 0.001)
	var depth_t: float = clampf((depth_from_surface - surface_darkness_start_depth) / depth_span, 0.0, 1.0)
	var dynamic_alpha: float = surface_darkness_alpha * depth_t

	var clear_center_world_variant: Variant = _get_sprite_opaque_center_global_position()
	var clear_center_world: Vector2 = clear_center_world_variant as Vector2 if clear_center_world_variant is Vector2 else global_position
	var clear_center_screen: Vector2 = _world_to_screen_position(clear_center_world)
	_surface_darkness_material.set_shader_parameter("clear_center", clear_center_screen)
	_surface_darkness_material.set_shader_parameter("clear_radius", surface_clear_radius)
	_surface_darkness_material.set_shader_parameter("edge_fade", surface_edge_fade)
	_surface_darkness_material.set_shader_parameter("darkness_alpha", dynamic_alpha)


func _update_crosshair_visibility() -> void:
	if aim_crosshair == null:
		return
	# Show crosshair only when player can actually fire a bullet right now.
	aim_crosshair.visible = _can_fire_bullet()


func _world_to_screen_position(world_position: Vector2) -> Vector2:
	var viewport: Viewport = get_viewport()
	var canvas_transform: Transform2D = viewport.get_canvas_transform()
	var screen_transform: Transform2D = viewport.get_screen_transform()
	return (screen_transform * canvas_transform) * world_position


func _get_grass_surface_world_y() -> Variant:
	var ground: Node = _get_diggable_ground()
	if ground == null:
		return null
	if not ground.has_method("get_grass_surface_world_y"):
		return null
	return ground.call("get_grass_surface_world_y")


func _update_auto_fire(delta: float) -> void:
	if not _is_shoot_held:
		return
	if pickaxe_equipped or axe_equipped:
		return
	if is_attacking:
		return
	if _is_reloading:
		return
	if auto_fire_shots_per_second <= 0.0:
		return

	_auto_fire_cooldown = maxf(_auto_fire_cooldown - delta, 0.0)
	if _auto_fire_cooldown > 0.0:
		return

	if _try_fire_bullet():
		_auto_fire_cooldown = 1.0 / auto_fire_shots_per_second
	else:
		# Avoid retrying every frame when empty.
		_auto_fire_cooldown = 0.1


func _update_equipped_pickaxe_visual() -> void:
	if _equipped_pickaxe_sprite == null:
		return
	_equipped_pickaxe_sprite.visible = pickaxe_equipped or axe_equipped
	if not (pickaxe_equipped or axe_equipped):
		return
	if axe_equipped:
		_equipped_pickaxe_sprite.texture = _create_axe_texture()
	else:
		_equipped_pickaxe_sprite.texture = _create_pickaxe_texture()

	var target_global: Variant = _get_sprite_purple_centroid_global_position()
	if not (target_global is Vector2):
		target_global = global_position + Vector2(0.0, -12.0)
	_equipped_pickaxe_sprite.position = visual.to_local(target_global as Vector2)
	_equipped_pickaxe_sprite.scale = Vector2(float(facing_direction), 1.0)


func _can_fire_bullet() -> bool:
	if is_dead:
		return false
	if pickaxe_equipped or axe_equipped:
		return false
	if _is_reloading:
		return false
	if ammo_in_mag <= 0:
		return false
	return true


func _try_fire_bullet() -> bool:
	if not _can_fire_bullet():
		_emit_ammo_state_changed()
		return false
	_align_facing_to_shot_direction()
	_fire_bullet()
	ammo_in_mag = maxi(ammo_in_mag - 1, 0)
	_emit_ammo_state_changed()
	return true


func _align_facing_to_shot_direction() -> void:
	var spawn_pos: Vector2 = get_bullet_spawn_global_position()
	var aim_pos: Vector2 = get_aim_global_position()
	var dx: float = aim_pos.x - spawn_pos.x
	if absf(dx) <= 0.001:
		return

	var shot_sign: int = 1 if dx > 0.0 else -1
	if shot_sign == facing_direction:
		return

	facing_direction = shot_sign
	visual.scale.x = facing_direction

func _physics_process(delta: float):
	if is_dead:
		return
	if top_bounce_cooldown_timer > 0.0:
		top_bounce_cooldown_timer = maxf(top_bounce_cooldown_timer - delta, 0.0)
	
	tick_jump_timers(delta)
	
	if not is_on_floor():
		velocity.y = clamp(velocity.y + world_gravity * delta, -INF, world_terminal_velocity)
	
	state_machine.call("physics_update", delta)
	var pre_slide_velocity_y: float = velocity.y
	move_and_slide()
	_check_top_enemy_bounce(pre_slide_velocity_y)
	_update_auto_pickup_jump_helper(delta)
	
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

func _fire_bullet() -> void:
	if combat_logic != null and combat_logic.has_method("fire_bullet"):
		combat_logic.call("fire_bullet", self, Callable(self, "get_aim_global_position"), bullet_speed)


func _try_dig_ground_at_cursor_if_allowed() -> void:
	var ground: Node = _get_diggable_ground()
	if ground == null:
		return
	if not ground.has_method("dig_at"):
		return

	var cursor_position: Vector2 = get_aim_global_position()
	if not _is_cursor_within_orange_dig_box(cursor_position):
		return
	_spawn_dig_preview(cursor_position)
	ground.call("dig_at", cursor_position, dig_radius)


func _try_chop_trees_at_cursor_if_allowed() -> void:
	var ground: Node = _get_diggable_ground()
	if ground == null:
		return
	if not ground.has_method("chop_trees_at"):
		return

	var cursor_position: Vector2 = get_aim_global_position()
	if not _is_cursor_within_orange_dig_box(cursor_position):
		return
	_spawn_dig_preview(cursor_position)
	ground.call("chop_trees_at", cursor_position, dig_radius)


func _is_cursor_within_orange_dig_box(cursor_global_position: Vector2) -> bool:
	var center: Variant = _get_sprite_orange_centroid_global_position()
	if not (center is Vector2):
		center = global_position
	var delta: Vector2 = cursor_global_position - (center as Vector2)
	return absf(delta.x) <= ORANGE_DIG_BOX_HALF_SIZE and absf(delta.y) <= ORANGE_DIG_BOX_HALF_SIZE


func _spawn_dig_preview(global_position: Vector2) -> void:
	var preview := Node2D.new()
	preview.set_script(DigPreviewEffectScript)
	preview.position = get_viewport().get_mouse_position()
	preview.set("radius", dig_radius)
	if crosshair_layer != null:
		crosshair_layer.add_child(preview)
	else:
		preview.global_position = global_position
		get_tree().current_scene.add_child(preview)


func _get_diggable_ground() -> Node:
	if _diggable_ground != null and is_instance_valid(_diggable_ground):
		return _diggable_ground
	_diggable_ground = get_tree().get_first_node_in_group(DIGGABLE_GROUND_GROUP_NAME)
	return _diggable_ground


func _update_reload(delta: float) -> void:
	if not _is_reloading:
		return
	_reload_time_left = maxf(_reload_time_left - delta, 0.0)
	if _reload_time_left <= 0.0:
		_finish_reload()
	_emit_ammo_state_changed()


func request_reload() -> void:
	if is_dead:
		return
	if _is_reloading:
		return
	if ammo_in_mag > 0:
		return
	if spare_magazines <= 0:
		return
	_is_reloading = true
	_reload_time_left = reload_duration_seconds
	_emit_ammo_state_changed()


func _finish_reload() -> void:
	_is_reloading = false
	_reload_time_left = 0.0
	spare_magazines = maxi(spare_magazines - 1, 0)
	ammo_in_mag = max(bullets_per_magazine, 0)


func get_aim_global_position() -> Vector2:
	return get_global_mouse_position()


func get_bullet_spawn_global_position() -> Vector2:
	var spawn_offset: Vector2 = Vector2(0.0, -3.0)
	var orange_centroid: Variant = _get_sprite_orange_centroid_global_position()
	if orange_centroid is Vector2:
		return (orange_centroid as Vector2) + spawn_offset

	var sprite_center: Variant = _get_sprite_opaque_center_global_position()
	if sprite_center is Vector2:
		return (sprite_center as Vector2) + spawn_offset

	var shape_node: CollisionShape2D = collision_shape_crouched if is_crouched else collision_shape_standing
	if shape_node != null:
		return shape_node.global_position + spawn_offset

	return global_position + spawn_offset


func _get_sprite_orange_centroid_global_position() -> Variant:
	if sprite == null:
		return null
	var texture: Texture2D = sprite.texture
	if texture == null:
		return null

	var img: Image = texture.get_image()
	if img == null:
		return null

	var centroid_in_frame: Variant = _get_cached_orange_centroid_in_current_frame(img)
	if not (centroid_in_frame is Vector2):
		return null

	var rect: Rect2 = sprite.get_rect()
	var local_in_sprite: Vector2 = rect.position + (centroid_in_frame as Vector2)
	return sprite.to_global(local_in_sprite)


func _get_sprite_purple_centroid_global_position() -> Variant:
	if sprite == null:
		return null
	var texture: Texture2D = sprite.texture
	if texture == null:
		return null

	var img: Image = texture.get_image()
	if img == null:
		return null

	var centroid_in_frame: Variant = _get_cached_purple_centroid_in_current_frame(img)
	if not (centroid_in_frame is Vector2):
		return null

	var rect: Rect2 = sprite.get_rect()
	var local_in_sprite: Vector2 = rect.position + (centroid_in_frame as Vector2)
	return sprite.to_global(local_in_sprite)


func _get_sprite_opaque_center_global_position() -> Variant:
	if sprite == null:
		return null
	var texture: Texture2D = sprite.texture
	if texture == null:
		return null

	var img: Image = texture.get_image()
	if img == null:
		return null

	var centroid_in_frame: Vector2 = _get_cached_opaque_centroid_in_current_frame(img)
	var rect: Rect2 = sprite.get_rect()
	var local_in_sprite: Vector2 = rect.position + centroid_in_frame
	return sprite.to_global(local_in_sprite)


func _get_cached_opaque_centroid_in_current_frame(img: Image) -> Vector2:
	var hframes: int = max(sprite.hframes, 1)
	var vframes: int = max(sprite.vframes, 1)
	var frame_index: int = sprite.frame
	var texture_path: String = sprite.texture.resource_path
	var cache_key: String = "%s:%d:%d:%d" % [texture_path, frame_index, hframes, vframes]
	if _opaque_centroid_cache.has(cache_key):
		return _opaque_centroid_cache[cache_key]

	var img_w: int = img.get_width()
	var img_h: int = img.get_height()
	if img_w <= 0 or img_h <= 0:
		return Vector2.ZERO

	var frame_w: int = int(img_w / hframes)
	var frame_h: int = int(img_h / vframes)
	if frame_w <= 0 or frame_h <= 0:
		return Vector2.ZERO

	var fx: int = (frame_index % hframes) * frame_w
	var fy: int = int(frame_index / hframes) * frame_h
	fx = clampi(fx, 0, max(img_w - frame_w, 0))
	fy = clampi(fy, 0, max(img_h - frame_h, 0))

	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: int = 0
	var sum_orange_x: float = 0.0
	var sum_orange_y: float = 0.0
	var orange_count: int = 0
	for y in range(fy, fy + frame_h):
		for x in range(fx, fx + frame_w):
			var px: Color = img.get_pixel(x, y)
			var a: float = px.a
			if a > 0.1:
				sum_x += float(x - fx) + 0.5
				sum_y += float(y - fy) + 0.5
				count += 1
				if _is_orangeish(px):
					sum_orange_x += float(x - fx) + 0.5
					sum_orange_y += float(y - fy) + 0.5
					orange_count += 1

	var centroid: Vector2
	if orange_count >= 20 and orange_count >= int(float(count) * 0.05):
		centroid = Vector2(sum_orange_x / float(orange_count), sum_orange_y / float(orange_count))
	elif count <= 0:
		centroid = Vector2(float(frame_w) * 0.5, float(frame_h) * 0.5)
	else:
		centroid = Vector2(sum_x / float(count), sum_y / float(count))

	_opaque_centroid_cache[cache_key] = centroid
	return centroid


func _get_cached_orange_centroid_in_current_frame(img: Image) -> Variant:
	var hframes: int = max(sprite.hframes, 1)
	var vframes: int = max(sprite.vframes, 1)
	var frame_index: int = sprite.frame
	var texture_path: String = sprite.texture.resource_path
	var cache_key: String = "orange_centroid:%s:%d:%d:%d" % [texture_path, frame_index, hframes, vframes]
	if _orange_centroid_cache.has(cache_key):
		return _orange_centroid_cache[cache_key]

	var img_w: int = img.get_width()
	var img_h: int = img.get_height()
	if img_w <= 0 or img_h <= 0:
		return null

	var frame_w: int = int(img_w / hframes)
	var frame_h: int = int(img_h / vframes)
	if frame_w <= 0 or frame_h <= 0:
		return null

	var fx: int = (frame_index % hframes) * frame_w
	var fy: int = int(frame_index / hframes) * frame_h
	fx = clampi(fx, 0, max(img_w - frame_w, 0))
	fy = clampi(fy, 0, max(img_h - frame_h, 0))

	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: int = 0
	for y in range(fy, fy + frame_h):
		for x in range(fx, fx + frame_w):
			var px: Color = img.get_pixel(x, y)
			if px.a <= 0.1:
				continue
			if not _is_orangeish(px):
				continue
			sum_x += float(x - fx) + 0.5
			sum_y += float(y - fy) + 0.5
			count += 1

	if count <= 0:
		_orange_centroid_cache[cache_key] = null
		return null

	var centroid: Vector2 = Vector2(sum_x / float(count), sum_y / float(count))
	_orange_centroid_cache[cache_key] = centroid
	return centroid


func _get_cached_purple_centroid_in_current_frame(img: Image) -> Variant:
	var hframes: int = max(sprite.hframes, 1)
	var vframes: int = max(sprite.vframes, 1)
	var frame_index: int = sprite.frame
	var texture_path: String = sprite.texture.resource_path
	var cache_key: String = "purple_centroid:%s:%d:%d:%d" % [texture_path, frame_index, hframes, vframes]
	if _purple_centroid_cache.has(cache_key):
		return _purple_centroid_cache[cache_key]

	var img_w: int = img.get_width()
	var img_h: int = img.get_height()
	if img_w <= 0 or img_h <= 0:
		return null

	var frame_w: int = int(img_w / hframes)
	var frame_h: int = int(img_h / vframes)
	if frame_w <= 0 or frame_h <= 0:
		return null

	var fx: int = (frame_index % hframes) * frame_w
	var fy: int = int(frame_index / hframes) * frame_h
	fx = clampi(fx, 0, max(img_w - frame_w, 0))
	fy = clampi(fy, 0, max(img_h - frame_h, 0))

	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: int = 0
	for y in range(fy, fy + frame_h):
		for x in range(fx, fx + frame_w):
			var px: Color = img.get_pixel(x, y)
			if px.a <= 0.1:
				continue
			if not _is_purpleish(px):
				continue
			sum_x += float(x - fx) + 0.5
			sum_y += float(y - fy) + 0.5
			count += 1

	if count <= 0:
		_purple_centroid_cache[cache_key] = null
		return null

	var centroid: Vector2 = Vector2(sum_x / float(count), sum_y / float(count))
	_purple_centroid_cache[cache_key] = centroid
	return centroid


func _is_orangeish(px: Color) -> bool:
	return px.r > 0.65 and px.g > 0.25 and px.b < 0.25 and px.r > px.g and px.g > px.b


func _is_purpleish(px: Color) -> bool:
	return px.r > 0.45 and px.b > 0.45 and px.g < 0.4 and px.b >= px.r

func _is_enemy_in_melee_range() -> bool:
	if combat_logic != null and combat_logic.has_method("is_enemy_in_melee_range"):
		return bool(combat_logic.call("is_enemy_in_melee_range", self, melee_range))
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
			var hurtbox_standing: CollisionShape2D = get_node_or_null("HurtBox/CollisionShapeStanding")
			if hurtbox_standing != null:
				hurtbox_standing.set_deferred("disabled", false)
			var hurtbox_crouched: CollisionShape2D = get_node_or_null("HurtBox/CollisionShapeCrouched")
			if hurtbox_crouched != null:
				hurtbox_crouched.set_deferred("disabled", true)
		collision_shapes.CROUCHED:
			collision_shape_standing.set_deferred("disabled", true)
			collision_shape_crouched.set_deferred("disabled", false)
			var hurtbox_standing: CollisionShape2D = get_node_or_null("HurtBox/CollisionShapeStanding")
			if hurtbox_standing != null:
				hurtbox_standing.set_deferred("disabled", true)
			var hurtbox_crouched: CollisionShape2D = get_node_or_null("HurtBox/CollisionShapeCrouched")
			if hurtbox_crouched != null:
				hurtbox_crouched.set_deferred("disabled", false)
			
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
	if health_logic != null and health_logic.has_method("apply_damage"):
		health_logic.call("apply_damage", self, amount)
		return

	# Fallback for safety (should not happen).
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


func heal(amount: int = 1) -> void:
	if is_dead:
		return
	if amount <= 0:
		return
	health = clampi(health + amount, 0, max_health)
	update_health_ui()


func _setup_inventory_ui() -> void:
	if not is_inside_tree():
		return

	if inventory_ui != null and is_instance_valid(inventory_ui):
		_connect_inventory_ui_signals()
		return

	# InventoryUI may not have run _ready() yet (and thus hasn't joined its
	# group). Retry for a few frames, but avoid infinite defers which can crash
	# headless tests.
	for _i in range(INVENTORY_UI_SETUP_MAX_RETRIES + 1):
		inventory_ui = get_tree().get_first_node_in_group(INVENTORY_UI_GROUP_NAME) as CanvasLayer
		if inventory_ui != null:
			break
		await get_tree().process_frame

	if inventory_ui == null:
		return

	_connect_inventory_ui_signals()
	_grant_initial_pickaxe_if_needed()


func _connect_inventory_ui_signals() -> void:
	if inventory_ui == null or not is_instance_valid(inventory_ui):
		return
	if inventory_ui.has_signal("item_requested_use"):
		var callable := Callable(self, "_on_inventory_item_use_requested")
		if not inventory_ui.is_connected("item_requested_use", callable):
			inventory_ui.connect("item_requested_use", callable)

	if inventory_ui.has_signal("magazine_reload_requested"):
		var reload_callable := Callable(self, "_on_inventory_magazine_reload_requested")
		if not inventory_ui.is_connected("magazine_reload_requested", reload_callable):
			inventory_ui.connect("magazine_reload_requested", reload_callable)

	_emit_ammo_state_changed()


func _grant_initial_pickaxe_if_needed() -> void:
	if _initial_pickaxe_granted:
		return
	if inventory_ui == null or not is_instance_valid(inventory_ui):
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "pickaxe", 1)
		_initial_pickaxe_granted = true


func _on_inventory_magazine_reload_requested() -> void:
	request_reload()


func _setup_item_pickups() -> void:
	for node in get_tree().get_nodes_in_group("item_apple"):
		_connect_apple_pickup(node)
	for node in get_tree().get_nodes_in_group("item_pickaxe"):
		_connect_pickaxe_pickup(node)
	for node in get_tree().get_nodes_in_group("item_axe"):
		_connect_axe_pickup(node)
	for node in get_tree().get_nodes_in_group("item_wood"):
		_connect_wood_pickup(node)
	for node in get_tree().get_nodes_in_group("item_ground_block"):
		_connect_ground_block_pickup(node)
	_spawn_initial_axe_pickup_if_needed()


func _on_tree_node_added(node: Node) -> void:
	if node == null:
		return
	if node.is_in_group("item_apple"):
		_connect_apple_pickup(node)
	if node.is_in_group("item_pickaxe"):
		_connect_pickaxe_pickup(node)
	if node.is_in_group("item_axe"):
		_connect_axe_pickup(node)
	if node.is_in_group("item_wood"):
		_connect_wood_pickup(node)
	if node.is_in_group("item_ground_block"):
		_connect_ground_block_pickup(node)


func _connect_apple_pickup(node: Node) -> void:
	if node == null or not node.has_signal("collected"):
		return
	var callable := Callable(self, "_on_apple_collected")
	if node.is_connected("collected", callable):
		pass
	else:
		node.connect("collected", callable, CONNECT_ONE_SHOT)
	if node.has_signal("pickup_requested"):
		var pickup_callable := Callable(self, "_on_apple_pickup_requested")
		if not node.is_connected("pickup_requested", pickup_callable):
			node.connect("pickup_requested", pickup_callable)


func _connect_pickaxe_pickup(node: Node) -> void:
	if node == null or not node.has_signal("collected"):
		return
	var callable := Callable(self, "_on_pickaxe_collected")
	if node.is_connected("collected", callable):
		pass
	else:
		node.connect("collected", callable, CONNECT_ONE_SHOT)
	if node.has_signal("pickup_requested"):
		var pickup_callable := Callable(self, "_on_pickaxe_pickup_requested")
		if not node.is_connected("pickup_requested", pickup_callable):
			node.connect("pickup_requested", pickup_callable)


func _connect_axe_pickup(node: Node) -> void:
	if node == null or not node.has_signal("collected"):
		return
	var callable := Callable(self, "_on_axe_collected")
	if node.is_connected("collected", callable):
		pass
	else:
		node.connect("collected", callable, CONNECT_ONE_SHOT)
	if node.has_signal("pickup_requested"):
		var pickup_callable := Callable(self, "_on_axe_pickup_requested")
		if not node.is_connected("pickup_requested", pickup_callable):
			node.connect("pickup_requested", pickup_callable)


func _connect_wood_pickup(node: Node) -> void:
	if node == null or not node.has_signal("collected"):
		return
	var callable := Callable(self, "_on_wood_collected")
	if node.is_connected("collected", callable):
		pass
	else:
		node.connect("collected", callable, CONNECT_ONE_SHOT)
	if node.has_signal("pickup_requested"):
		var pickup_callable := Callable(self, "_on_wood_pickup_requested")
		if not node.is_connected("pickup_requested", pickup_callable):
			node.connect("pickup_requested", pickup_callable)


func _connect_ground_block_pickup(node: Node) -> void:
	if node == null or not node.has_signal("collected"):
		return
	var callable := Callable(self, "_on_ground_block_collected")
	if node.is_connected("collected", callable):
		pass
	else:
		node.connect("collected", callable, CONNECT_ONE_SHOT)
	if node.has_signal("pickup_requested"):
		var pickup_callable := Callable(self, "_on_ground_block_pickup_requested")
		if not node.is_connected("pickup_requested", pickup_callable):
			node.connect("pickup_requested", pickup_callable)


func _on_apple_collected(amount: int) -> void:
	if inventory_ui == null:
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "apple", amount)


func _on_pickaxe_collected(amount: int) -> void:
	if inventory_ui == null:
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "pickaxe", amount)


func _on_axe_collected(amount: int) -> void:
	if inventory_ui == null:
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "axe", amount)


func _on_wood_collected(amount: int) -> void:
	if inventory_ui == null:
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "wood", amount)


func _on_ground_block_collected(amount: int) -> void:
	if inventory_ui == null:
		return
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "ground_block", amount)

func _on_apple_pickup_requested(drop: Node2D) -> void:
	_set_auto_pickup_target(drop)


func _on_pickaxe_pickup_requested(drop: Node2D) -> void:
	_set_auto_pickup_target(drop)


func _on_axe_pickup_requested(drop: Node2D) -> void:
	_set_auto_pickup_target(drop)


func _on_wood_pickup_requested(drop: Node2D) -> void:
	_set_auto_pickup_target(drop)


func _on_ground_block_pickup_requested(drop: Node2D) -> void:
	_set_auto_pickup_target(drop)


func _set_auto_pickup_target(target: Node2D) -> void:
	if is_dead:
		return
	if target == null or not is_instance_valid(target):
		return
	_auto_pickup_target = target
	_auto_pickup_stuck_time = 0.0
	force_stand()
	if _auto_pickup_target.has_method("request_pickup"):
		_auto_pickup_target.call("request_pickup")


func _update_auto_pickup_movement() -> void:
	if _auto_pickup_target == null:
		return
	if not is_instance_valid(_auto_pickup_target):
		_auto_pickup_target = null
		return

	var requested_variant: Variant = true
	if _auto_pickup_target.has_method("is_pickup_requested"):
		requested_variant = _auto_pickup_target.call("is_pickup_requested")
	if requested_variant is bool and not (requested_variant as bool):
		_auto_pickup_target = null
		_auto_pickup_stuck_time = 0.0
		return

	var target_position: Vector2 = _auto_pickup_target.global_position
	if _auto_pickup_target.has_method("get_pickup_target_position"):
		var target_variant: Variant = _auto_pickup_target.call("get_pickup_target_position")
		if target_variant is Vector2:
			target_position = target_variant as Vector2

	var delta_x: float = target_position.x - global_position.x
	if absf(delta_x) <= maxf(auto_pickup_stop_distance, 1.0):
		direction = 0.0
	else:
		direction = 1.0 if delta_x > 0.0 else -1.0
		facing_direction = 1 if direction > 0.0 else -1
		visual.scale.x = facing_direction


func _update_auto_pickup_jump_helper(delta: float) -> void:
	if _auto_pickup_target == null:
		_auto_pickup_stuck_time = 0.0
		return
	if not is_instance_valid(_auto_pickup_target):
		_auto_pickup_target = null
		_auto_pickup_stuck_time = 0.0
		return
	if not is_on_floor():
		_auto_pickup_stuck_time = 0.0
		return
	if absf(direction) <= 0.01:
		_auto_pickup_stuck_time = 0.0
		return

	var target_dx: float = _auto_pickup_target.global_position.x - global_position.x
	if absf(target_dx) <= maxf(auto_pickup_stop_distance, 1.0):
		_auto_pickup_stuck_time = 0.0
		return

	if absf(velocity.x) < 4.0:
		_auto_pickup_stuck_time += delta
	else:
		_auto_pickup_stuck_time = 0.0

	if _auto_pickup_stuck_time >= auto_pickup_jump_delay:
		queue_jump()
		_auto_pickup_stuck_time = 0.0


func _on_inventory_item_use_requested(item_id: String) -> void:
	if item_id == "apple":
		# InventoryUI is responsible for consuming the item. We only apply the effect.
		if OS.is_debug_build():
			print("Player: heal from apple")
		heal(1)
		return
	if item_id == "pickaxe":
		pickaxe_equipped = not pickaxe_equipped
		if pickaxe_equipped:
			axe_equipped = false
		return
	if item_id == "axe":
		axe_equipped = not axe_equipped
		if axe_equipped:
			pickaxe_equipped = false
		return


func _create_axe_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))

	for y in range(5, 14):
		for x in range(7, 9):
			img.set_pixel(x, y, Color(0.46, 0.24, 0.11, 1.0))

	for y in range(3, 8):
		for x in range(3, 11):
			img.set_pixel(x, y, Color(0.72, 0.72, 0.78, 1.0))

	for y in range(4, 7):
		for x in range(2, 4):
			img.set_pixel(x, y, Color(0.66, 0.66, 0.72, 1.0))

	return ImageTexture.create_from_image(img)


func _spawn_initial_axe_pickup_if_needed() -> void:
	if _initial_axe_spawned:
		return
	if AxePickupScene == null:
		return
	if get_tree().get_nodes_in_group("item_axe").size() > 0:
		_initial_axe_spawned = true
		return

	if inventory_ui != null and is_instance_valid(inventory_ui):
		if inventory_ui.has_method("get_count"):
			var axe_count: int = int(inventory_ui.call("get_count", "axe"))
			if axe_count > 0:
				_initial_axe_spawned = true
				return

	var ground: Node = _get_diggable_ground()
	if ground == null:
		return
	if not ground.has_method("get_grass_surface_world_y"):
		return

	var grass_y_variant: Variant = ground.call("get_grass_surface_world_y")
	if not (grass_y_variant is float):
		return
	var grass_y: float = grass_y_variant as float

	var axe_pickup := AxePickupScene.instantiate()
	if axe_pickup == null:
		return
	if axe_pickup is Node2D:
		var axe_node: Node2D = axe_pickup as Node2D
		axe_node.global_position = Vector2(global_position.x + 50.0, grass_y - 8.0)

	var spawn_parent: Node = get_tree().current_scene
	if spawn_parent == null:
		spawn_parent = get_parent()
	if spawn_parent == null:
		spawn_parent = get_tree().root
	if spawn_parent == null:
		return
	spawn_parent.add_child(axe_pickup)
	_connect_axe_pickup(axe_pickup)
	_initial_axe_spawned = true

func die() -> void:
	if is_dead:
		return
		
	is_dead = true
	velocity = Vector2.ZERO
	
	var death_screen := DeathScreenScene.instantiate()
	get_tree().current_scene.add_child(death_screen)
	if death_screen.has_signal("restart_requested"):
		death_screen.connect("restart_requested", Callable(GameFlow, "restart_game"), CONNECT_ONE_SHOT)
	if death_screen.has_signal("menu_requested"):
		death_screen.connect("menu_requested", Callable(GameFlow, "go_to_main_menu"), CONNECT_ONE_SHOT)
	GameFlow.set_paused(true)
