extends Node2D

signal climb_zone_entered(vehicle: Node2D, player: Node2D, target_global_position: Vector2)
signal climb_zone_exited(vehicle: Node2D, player: Node2D)

const DIGGABLE_GROUND_GROUP_NAME := "diggable_ground"
const PLAYER_GROUP_NAME := "player"
const FUEL_PROMPT_TEXT := "添加燃料"

@export var snap_visual_bottom_to_ground_top_on_ready: bool = true
@export var snap_visual_bottom_offset_y: float = 0.0
@export_range(0.0, 480.0, 1.0) var drive_speed_px_per_second: float = 90.0
@export_range(1, 999, 1) var max_fuel: int = 100
@export_range(0, 999, 1) var initial_fuel: int = 0
@export_range(1, 99, 1) var fuel_per_ground_block: int = 5
@export_range(0.0, 1024.0, 1.0) var refuel_prompt_hide_distance_px: float = 120.0
@export_range(0.1, 10.0, 0.1) var fuel_drain_interval_seconds: float = 3.0
@export_range(1, 99, 1) var fuel_drain_amount_per_interval: int = 1

@onready var visual: Sprite2D = $Visual
@onready var terrain_body: PhysicsBody2D = $TerrainBody
@onready var fuel_interact_area: Area2D = $FuelInteractArea
@onready var fuel_interact_shape_node: CollisionShape2D = $FuelInteractArea/CollisionShape2D
@onready var fuel_prompt_label: Label = $FuelPromptLabel
@onready var fuel_value_label: Label = $FuelValueLabel
@onready var drive_control_area: Area2D = $DriveControlArea
@onready var left_climb_area: Area2D = $LeftClimbArea
@onready var right_climb_area: Area2D = $RightClimbArea
@onready var left_climb_target: Marker2D = $LeftClimbTarget
@onready var right_climb_target: Marker2D = $RightClimbTarget

var _players_in_drive_zone: Array[CharacterBody2D] = []
var _drive_left_pressed: bool = false
var _drive_right_pressed: bool = false
var _current_fuel: int = 0
var _is_refuel_prompt_active: bool = false
var _fuel_drain_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("vehicle_painting_19")
	_current_fuel = clampi(initial_fuel, 0, max_fuel)
	fuel_interact_area.input_pickable = true
	fuel_interact_area.input_event.connect(_on_fuel_interact_area_input_event)
	_set_refuel_prompt_active(false)
	if snap_visual_bottom_to_ground_top_on_ready:
		call_deferred("_snap_visual_bottom_to_ground_top")
	drive_control_area.body_entered.connect(_on_drive_control_area_body_entered)
	drive_control_area.body_exited.connect(_on_drive_control_area_body_exited)
	left_climb_area.body_entered.connect(_on_left_climb_area_body_entered)
	left_climb_area.body_exited.connect(_on_left_climb_area_body_exited)
	right_climb_area.body_entered.connect(_on_right_climb_area_body_entered)
	right_climb_area.body_exited.connect(_on_right_climb_area_body_exited)


func _physics_process(delta: float) -> void:
	_auto_hide_refuel_prompt_if_player_far()
	var drive_input: float = _get_drive_input_axis()
	if absf(drive_input) <= 0.001:
		return
	if not _has_driver_on_top():
		return
	if _current_fuel <= 0:
		return
	var delta_x: float = drive_input * drive_speed_px_per_second * delta
	if absf(delta_x) <= 0.001:
		return
	global_position.x += delta_x
	_carry_top_players(delta_x)
	_drain_fuel_while_moving(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null:
		return
	if key_event.echo:
		return
	var is_pressed: bool = key_event.pressed
	var physical_keycode: int = key_event.physical_keycode
	var keycode: int = key_event.keycode
	if physical_keycode == KEY_LEFT or keycode == KEY_LEFT:
		_drive_left_pressed = is_pressed
		return
	if physical_keycode == KEY_RIGHT or keycode == KEY_RIGHT:
		_drive_right_pressed = is_pressed
		return


func _input(event: InputEvent) -> void:
	_try_activate_refuel_prompt_from_mouse_event(event)


func _on_fuel_interact_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_try_activate_refuel_prompt_from_mouse_event(event)


func _try_activate_refuel_prompt_from_mouse_event(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button == null:
		return
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	var mouse_world_position: Vector2 = get_global_mouse_position()
	if not _is_mouse_over_fuel_interact_region(mouse_world_position):
		return
	if not _is_any_player_near_refuel_point():
		_set_refuel_prompt_active(false)
		return
	_set_refuel_prompt_active(true)
	get_viewport().set_input_as_handled()


func _is_mouse_over_fuel_interact_region(mouse_global_position: Vector2) -> bool:
	if fuel_interact_shape_node == null:
		return false
	var rect_shape: RectangleShape2D = fuel_interact_shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return false
	var local_point: Vector2 = fuel_interact_shape_node.to_local(mouse_global_position)
	var half_size: Vector2 = rect_shape.size * 0.5
	return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y


func _on_left_climb_area_body_entered(body: Node) -> void:
	_emit_zone_entered_if_player(body, left_climb_target.global_position)


func _on_right_climb_area_body_entered(body: Node) -> void:
	_emit_zone_entered_if_player(body, right_climb_target.global_position)


func _on_left_climb_area_body_exited(body: Node) -> void:
	_emit_zone_exited_if_player(body)


func _on_right_climb_area_body_exited(body: Node) -> void:
	_emit_zone_exited_if_player(body)


func _emit_zone_entered_if_player(body: Node, target_global_position: Vector2) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var player_node: Node2D = body as Node2D
	if player_node == null:
		return
	climb_zone_entered.emit(self, player_node, target_global_position)


func _emit_zone_exited_if_player(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var player_node: Node2D = body as Node2D
	if player_node == null:
		return
	climb_zone_exited.emit(self, player_node)


func _on_drive_control_area_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group(PLAYER_GROUP_NAME):
		return
	var player_node: CharacterBody2D = body as CharacterBody2D
	if player_node == null:
		return
	if _players_in_drive_zone.has(player_node):
		return
	_players_in_drive_zone.append(player_node)


func _on_drive_control_area_body_exited(body: Node) -> void:
	if body == null:
		return
	var player_node: CharacterBody2D = body as CharacterBody2D
	if player_node == null:
		return
	_players_in_drive_zone.erase(player_node)


func _has_driver_on_top() -> bool:
	_prune_invalid_drive_players()
	for player_node: CharacterBody2D in _players_in_drive_zone:
		if _is_player_standing_on_vehicle_top(player_node):
			return true
	return false


func _carry_top_players(delta_x: float) -> void:
	_prune_invalid_drive_players()
	for player_node: CharacterBody2D in _players_in_drive_zone:
		if not _is_player_standing_on_vehicle_top(player_node):
			continue
		player_node.global_position.x += delta_x


func _is_player_standing_on_vehicle_top(player_node: CharacterBody2D) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false
	if not player_node.is_on_floor():
		return false
	var collision_count: int = player_node.get_slide_collision_count()
	for collision_index in range(collision_count):
		var collision: KinematicCollision2D = player_node.get_slide_collision(collision_index)
		if collision == null:
			continue
		if collision.get_collider() != terrain_body:
			continue
		var floor_normal: Vector2 = collision.get_normal()
		if floor_normal.dot(Vector2.UP) >= 0.6:
			return true
	return false


func _prune_invalid_drive_players() -> void:
	var valid_players: Array[CharacterBody2D] = []
	for player_node: CharacterBody2D in _players_in_drive_zone:
		if player_node == null:
			continue
		if not is_instance_valid(player_node):
			continue
		valid_players.append(player_node)
	_players_in_drive_zone = valid_players


func try_refuel_with_ground_block() -> bool:
	if not _is_refuel_prompt_active:
		return false
	if _current_fuel >= max_fuel:
		_set_refuel_prompt_active(false)
		return false
	_current_fuel = mini(_current_fuel + fuel_per_ground_block, max_fuel)
	_set_refuel_prompt_active(_current_fuel < max_fuel)
	return true


func _set_refuel_prompt_active(active: bool) -> void:
	_is_refuel_prompt_active = active and _current_fuel < max_fuel
	if fuel_prompt_label != null:
		fuel_prompt_label.text = FUEL_PROMPT_TEXT
		fuel_prompt_label.visible = _is_refuel_prompt_active
	if fuel_value_label != null:
		fuel_value_label.text = "%d/%d" % [_current_fuel, max_fuel]
		fuel_value_label.visible = _is_refuel_prompt_active


func _drain_fuel_while_moving(delta: float) -> void:
	if _current_fuel <= 0:
		_fuel_drain_elapsed = 0.0
		return
	if fuel_drain_interval_seconds <= 0.0:
		return
	_fuel_drain_elapsed += delta
	if _fuel_drain_elapsed < fuel_drain_interval_seconds:
		return
	var drain_ticks: int = int(floor(_fuel_drain_elapsed / fuel_drain_interval_seconds))
	_fuel_drain_elapsed -= float(drain_ticks) * fuel_drain_interval_seconds
	var total_fuel_cost: int = drain_ticks * fuel_drain_amount_per_interval
	if total_fuel_cost <= 0:
		return
	_current_fuel = maxi(_current_fuel - total_fuel_cost, 0)
	_set_refuel_prompt_active(_is_refuel_prompt_active)
	if _current_fuel <= 0:
		_fuel_drain_elapsed = 0.0


func _auto_hide_refuel_prompt_if_player_far() -> void:
	if not _is_refuel_prompt_active:
		return
	if _is_any_player_near_refuel_point():
		return
	_set_refuel_prompt_active(false)


func _is_any_player_near_refuel_point() -> bool:
	if refuel_prompt_hide_distance_px <= 0.0:
		return true
	var distance_limit_sq: float = refuel_prompt_hide_distance_px * refuel_prompt_hide_distance_px
	var refuel_point: Vector2 = _get_refuel_point_global_position()
	for player_variant: Variant in get_tree().get_nodes_in_group(PLAYER_GROUP_NAME):
		var player_node: Node2D = player_variant as Node2D
		if player_node == null:
			continue
		if not is_instance_valid(player_node):
			continue
		var distance_sq: float = player_node.global_position.distance_squared_to(refuel_point)
		if distance_sq <= distance_limit_sq:
			return true
	return false


func _get_refuel_point_global_position() -> Vector2:
	if fuel_interact_shape_node != null:
		return fuel_interact_shape_node.global_position
	if fuel_interact_area != null:
		return fuel_interact_area.global_position
	return global_position


func _get_drive_input_axis() -> float:
	if _drive_left_pressed == _drive_right_pressed:
		return 0.0
	return -1.0 if _drive_left_pressed else 1.0


func _snap_visual_bottom_to_ground_top() -> void:
	var ground_node: Node = get_tree().get_first_node_in_group(DIGGABLE_GROUND_GROUP_NAME)
	if ground_node == null:
		return
	if not ground_node.has_method("get_grass_surface_world_y"):
		return
	var ground_surface_variant: Variant = ground_node.call("get_grass_surface_world_y")
	if not (ground_surface_variant is float or ground_surface_variant is int):
		return
	var ground_surface_world_y: float = float(ground_surface_variant)
	var visual_bottom_local_y: float = _get_visual_bottom_local_y()
	global_position.y = ground_surface_world_y - visual_bottom_local_y + snap_visual_bottom_offset_y


func _get_visual_bottom_local_y() -> float:
	if visual == null:
		return 0.0
	var visual_rect: Rect2 = visual.get_rect()
	var bottom_left_visual_space := Vector2(visual_rect.position.x, visual_rect.position.y + visual_rect.size.y)
	var bottom_right_visual_space := visual_rect.position + visual_rect.size
	var bottom_left_vehicle_space: Vector2 = to_local(visual.to_global(bottom_left_visual_space))
	var bottom_right_vehicle_space: Vector2 = to_local(visual.to_global(bottom_right_visual_space))
	return maxf(bottom_left_vehicle_space.y, bottom_right_vehicle_space.y)
