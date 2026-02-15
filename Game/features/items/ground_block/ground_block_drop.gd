extends CharacterBody2D

signal collected(amount: int)
signal pickup_requested(drop: Node2D)

@export var amount: int = 1
@export var fall_gravity: float = 720.0
@export var max_fall_speed: float = 240.0
@export_range(0.0, 200.0, 1.0) var bounce_up_speed: float = 36.0
@export_range(-120.0, 120.0, 1.0) var spawn_horizontal_speed: float = 40.0
@export var horizontal_damping: float = 420.0
@export_range(1.0, 64.0, 1.0) var pickup_collect_distance: float = 14.0

const TERRAIN_COLLISION_MASK: int = 1 << 2

@onready var pickup_area: Area2D = $PickupArea
@onready var visual: Polygon2D = $Visual

var _velocity: Vector2 = Vector2.ZERO
var _is_pickup_requested: bool = false


func _enter_tree() -> void:
	add_to_group("item_ground_block")


func _ready() -> void:
	input_pickable = true
	collision_layer = 0
	collision_mask = TERRAIN_COLLISION_MASK
	pickup_area.input_pickable = true
	pickup_area.collision_layer = 1
	pickup_area.collision_mask = 1
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.input_event.connect(_on_pickup_area_input_event)
	input_event.connect(_on_input_event)
	_velocity = Vector2(spawn_horizontal_speed, -bounce_up_speed)


func _physics_process(delta: float) -> void:
	_velocity.y = minf(_velocity.y + fall_gravity * delta, max_fall_speed)
	_velocity.x = move_toward(_velocity.x, 0.0, horizontal_damping * delta)
	velocity = _velocity
	move_and_slide()
	_velocity = velocity


func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	_collect()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return
	if not _is_mouse_on_opaque_visual():
		return
	request_pickup()


func _on_pickup_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_on_input_event(_viewport, event, _shape_idx)


func _is_mouse_on_opaque_visual() -> bool:
	if visual == null or not visual.visible:
		return false
	var mouse_global: Vector2 = get_global_mouse_position()
	var local_in_visual: Vector2 = visual.to_local(mouse_global)
	var points: PackedVector2Array = visual.polygon
	if points.is_empty():
		return false
	return Geometry2D.is_point_in_polygon(local_in_visual, points)


func request_pickup() -> void:
	if _is_pickup_requested:
		return
	_is_pickup_requested = true
	if visual != null:
		visual.color = visual.color.lightened(0.25)
	pickup_requested.emit(self)


func is_pickup_requested() -> bool:
	return _is_pickup_requested


func get_pickup_target_position() -> Vector2:
	return global_position


func try_collect_with(body: Node) -> bool:
	if not _is_pickup_requested:
		return false
	if body == null:
		return false
	if not body.is_in_group("player"):
		return false
	if not (body is Node2D):
		return false
	var body_node: Node2D = body as Node2D
	if body_node.global_position.distance_squared_to(global_position) > pickup_collect_distance * pickup_collect_distance:
		return false
	_collect()
	return true


func _collect() -> void:
	if not is_inside_tree():
		return
	collected.emit(amount)
	queue_free()
