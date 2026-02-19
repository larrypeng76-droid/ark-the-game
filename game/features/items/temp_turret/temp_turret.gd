extends Node2D

const PLACED_TURRET_GROUP_NAME := "placed_temp_turret"
const TEMP_TURRET_TEXTURE_PATH := "res://Resources/lib/临时炮塔.png"
const PlayerBulletScene := preload("res://game/player/player_bullet.tscn")
const TURRET_TARGET_SIZE_PX := Vector2(60.0, 40.0)
const TURRET_VISUAL_SUPERSAMPLE: float = 4.0
const COLLISION_ALPHA_THRESHOLD := 0.1
const OPAQUE_ALPHA_THRESHOLD := 0.95
const FALL_GRAVITY_PX := 2400.0
const FALL_MAX_SPEED_PX := 900.0
const FALL_COLLISION_MASK: int = (1 << 0) | (1 << 1) | (1 << 2)

static var _cache_ready: bool = false
static var _cached_texture: Texture2D
static var _cached_visual_scale: Vector2 = Vector2.ONE
static var _cached_centroid_px: Vector2 = TURRET_TARGET_SIZE_PX * 0.5
static var _cached_brown_centroid_offset_px: Vector2 = Vector2.ZERO
static var _cached_bottom_from_centroid_px: float = TURRET_TARGET_SIZE_PX.y * 0.5
static var _cached_polygons: Array[PackedVector2Array] = []
static var _cached_has_collision_polygons: bool = false
static var _cached_query_shape_size: Vector2 = TURRET_TARGET_SIZE_PX
static var _cached_query_shape_offset: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var body: StaticBody2D = $Body

@export_range(0.05, 5.0, 0.01) var fire_interval_sec: float = 0.1667
@export_range(80.0, 6000.0, 10.0) var target_range_px: float = 2400.0
@export_range(80.0, 2400.0, 10.0) var bullet_speed_px: float = 620.0
@export_range(1, 99, 1) var bullet_damage: int = 1

var _is_falling: bool = false
var _fall_velocity_y: float = 0.0
var _fire_cooldown_sec: float = 0.0


func _ready() -> void:
	add_to_group(PLACED_TURRET_GROUP_NAME)
	_ensure_cached_visual_data()
	_apply_cached_visual_data()
	_rebuild_collision_from_cache()


func set_cell_world_position(cell_center_world: Vector2, block_size_px: float) -> void:
	var placement_y: float = (
		cell_center_world.y
		- block_size_px * 0.5
		- _cached_bottom_from_centroid_px
	)
	global_position = Vector2(cell_center_world.x, placement_y)
	_resolve_initial_overlap_by_lifting()
	_is_falling = true
	_fall_velocity_y = 0.0


func set_click_world_position(click_world_position: Vector2) -> void:
	global_position = click_world_position
	_resolve_initial_overlap_by_lifting()
	_is_falling = true
	_fall_velocity_y = 0.0


func apply_visual_record(record: Dictionary) -> void:
	var rotation_variant: Variant = record.get("rotation", 0.0)
	var visual_rotation: float = float(rotation_variant)
	rotation = visual_rotation


func _apply_cached_visual_data() -> void:
	if sprite == null:
		return
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = _cached_texture
	sprite.scale = _cached_visual_scale
	var half_size: Vector2 = TURRET_TARGET_SIZE_PX * 0.5
	var scale_x: float = _cached_visual_scale.x if absf(_cached_visual_scale.x) > 0.0001 else 1.0
	var scale_y: float = _cached_visual_scale.y if absf(_cached_visual_scale.y) > 0.0001 else 1.0
	var offset_world: Vector2 = half_size - _cached_centroid_px
	sprite.offset = Vector2(offset_world.x / scale_x, offset_world.y / scale_y)


func _rebuild_collision_from_cache() -> void:
	if body == null:
		return
	for child: Node in body.get_children():
		child.queue_free()

	if _cached_has_collision_polygons:
		for polygon_points: PackedVector2Array in _cached_polygons:
			if polygon_points.size() < 3:
				continue
			var collision_polygon := CollisionPolygon2D.new()
			collision_polygon.polygon = polygon_points
			collision_polygon.position = -_cached_centroid_px
			body.add_child(collision_polygon)

	if body.get_child_count() == 0:
		var shape := RectangleShape2D.new()
		shape.size = TURRET_TARGET_SIZE_PX
		var collision_shape := CollisionShape2D.new()
		collision_shape.shape = shape
		collision_shape.position = (TURRET_TARGET_SIZE_PX * 0.5) - _cached_centroid_px
		body.add_child(collision_shape)


func _physics_process(delta: float) -> void:
	if _is_falling:
		var request_delta_y: float = _next_fall_delta_y(delta)
		if request_delta_y > 0.0:
			var safe_fraction: float = _compute_fall_safe_fraction(request_delta_y)
			global_position.y += request_delta_y * safe_fraction
			if safe_fraction < 1.0:
				_is_falling = false
				_fall_velocity_y = 0.0
			elif _is_touching_any_collision():
				_is_falling = false
				_fall_velocity_y = 0.0
	_process_turret_combat(delta)


func _next_fall_delta_y(delta: float) -> float:
	_fall_velocity_y = minf(_fall_velocity_y + FALL_GRAVITY_PX * delta, FALL_MAX_SPEED_PX)
	return _fall_velocity_y * delta


func _compute_fall_safe_fraction(delta_y: float) -> float:
	var probe_shape := RectangleShape2D.new()
	probe_shape.size = _cached_query_shape_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	query.transform = Transform2D(0.0, global_position + _cached_query_shape_offset)
	query.motion = Vector2(0.0, delta_y)
	query.collision_mask = FALL_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [body.get_rid()]

	var cast_result: PackedFloat32Array = get_world_2d().direct_space_state.cast_motion(query)
	if cast_result.is_empty():
		return 1.0
	return clampf(cast_result[0], 0.0, 1.0)


func _is_touching_any_collision() -> bool:
	var probe_shape := RectangleShape2D.new()
	probe_shape.size = _cached_query_shape_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	query.transform = Transform2D(0.0, global_position + _cached_query_shape_offset)
	query.collision_mask = FALL_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [body.get_rid()]
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 8)
	return not hits.is_empty()


func _resolve_initial_overlap_by_lifting() -> void:
	if not is_inside_tree():
		return
	if not is_node_ready():
		return
	if body == null or not is_instance_valid(body):
		return
	var max_lift_px: int = 160
	var step_px: float = 1.0
	var lift_steps: int = 0
	while _is_touching_any_collision() and lift_steps < max_lift_px:
		global_position.y -= step_px
		lift_steps += 1


func _ensure_cached_visual_data() -> void:
	if _cache_ready:
		return

	var source_image: Image = Image.load_from_file(TEMP_TURRET_TEXTURE_PATH)
	if source_image == null or source_image.is_empty():
		_cache_ready = true
		return

	var target_width: int = maxi(int(TURRET_TARGET_SIZE_PX.x), 1)
	var target_height: int = maxi(int(TURRET_TARGET_SIZE_PX.y), 1)
	var render_width: int = maxi(int(round(float(target_width) * TURRET_VISUAL_SUPERSAMPLE)), target_width)
	var render_height: int = maxi(int(round(float(target_height) * TURRET_VISUAL_SUPERSAMPLE)), target_height)

	var visual_image_variant: Variant = source_image.duplicate()
	var visual_image: Image = visual_image_variant as Image
	if visual_image == null:
		visual_image = source_image
	visual_image.resize(render_width, render_height, Image.INTERPOLATE_LANCZOS)
	_cached_texture = ImageTexture.create_from_image(visual_image)
	_cached_visual_scale = Vector2(
		float(target_width) / float(render_width),
		float(target_height) / float(render_height)
	)

	var physics_image_variant: Variant = source_image.duplicate()
	var physics_image: Image = physics_image_variant as Image
	if physics_image == null:
		physics_image = source_image
	physics_image.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)
	var fallback_center := Vector2(float(target_width), float(target_height)) * 0.5
	var centroid_variant: Variant = _compute_alpha_centroid(physics_image)
	_cached_centroid_px = centroid_variant as Vector2 if centroid_variant is Vector2 else fallback_center
	_cached_brown_centroid_offset_px = _compute_brown_centroid_offset(physics_image, _cached_centroid_px)

	var bottom_variant: Variant = _compute_alpha_bottom_y(physics_image)
	if bottom_variant is float:
		var alpha_bottom_y: float = bottom_variant as float
		_cached_bottom_from_centroid_px = maxf(alpha_bottom_y - _cached_centroid_px.y, 0.0)
	else:
		_cached_bottom_from_centroid_px = TURRET_TARGET_SIZE_PX.y * 0.5

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(physics_image, COLLISION_ALPHA_THRESHOLD)
	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, physics_image.get_size()), 0.5)
	_cached_polygons.clear()
	for polygon_points: PackedVector2Array in polygons:
		if polygon_points.size() < 3:
			continue
		_cached_polygons.append(polygon_points)
	_cached_has_collision_polygons = not _cached_polygons.is_empty()
	_update_cached_query_shape_bounds(physics_image)
	_cache_ready = true


func _compute_alpha_centroid(image: Image) -> Variant:
	if image == null or image.is_empty():
		return null
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	for y in range(height):
		for x in range(width):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a < OPAQUE_ALPHA_THRESHOLD:
				continue
			sum_x += float(x) + 0.5
			sum_y += float(y) + 0.5
			count += 1
	if count <= 0:
		return null
	return Vector2(sum_x / float(count), sum_y / float(count))


func _compute_alpha_bottom_y(image: Image) -> Variant:
	if image == null or image.is_empty():
		return null
	var width: int = image.get_width()
	var height: int = image.get_height()
	var found: bool = false
	var max_y: float = 0.0
	for y in range(height):
		for x in range(width):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a < OPAQUE_ALPHA_THRESHOLD:
				continue
			found = true
			max_y = maxf(max_y, float(y) + 0.5)
	if not found:
		return null
	return max_y


func _update_cached_query_shape_bounds(image: Image) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	var found: bool = false
	var min_x: int = width - 1
	var min_y: int = height - 1
	var max_x: int = 0
	var max_y: int = 0
	for y in range(height):
		for x in range(width):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a < OPAQUE_ALPHA_THRESHOLD:
				continue
			found = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if not found:
		_cached_query_shape_size = TURRET_TARGET_SIZE_PX
		_cached_query_shape_offset = Vector2.ZERO
		return

	var min_center_x: float = float(min_x) + 0.5
	var min_center_y: float = float(min_y) + 0.5
	var max_center_x: float = float(max_x) + 0.5
	var max_center_y: float = float(max_y) + 0.5
	var size_x: float = maxf(max_center_x - min_center_x + 1.0, 1.0)
	var size_y: float = maxf(max_center_y - min_center_y + 1.0, 1.0)
	_cached_query_shape_size = Vector2(size_x, size_y)
	var bbox_center := Vector2(
		(min_center_x + max_center_x) * 0.5,
		(min_center_y + max_center_y) * 0.5
	)
	_cached_query_shape_offset = bbox_center - _cached_centroid_px


func _process_turret_combat(delta: float) -> void:
	_fire_cooldown_sec = maxf(_fire_cooldown_sec - delta, 0.0)
	var target_enemy: Node2D = _find_nearest_enemy()
	_try_fire_at_target(target_enemy)


func _find_nearest_enemy() -> Node2D:
	if not is_inside_tree():
		return null
	var max_distance_sq: float = target_range_px * target_range_px
	var closest_enemy: Node2D
	var closest_distance_sq: float = max_distance_sq
	var enemy_nodes: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for enemy_node: Node in enemy_nodes:
		if not (enemy_node is Node2D):
			continue
		var enemy: Node2D = enemy_node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.is_queued_for_deletion():
			continue
		var distance_sq: float = global_position.distance_squared_to(enemy.global_position)
		if distance_sq > closest_distance_sq:
			continue
		closest_distance_sq = distance_sq
		closest_enemy = enemy
	return closest_enemy


func _try_fire_at_target(target_enemy: Node2D) -> void:
	if _fire_cooldown_sec > 0.0:
		return
	if target_enemy == null or not is_instance_valid(target_enemy):
		return
	if PlayerBulletScene == null:
		return
	var direction: Vector2 = _compute_fire_direction(target_enemy)
	if direction.length_squared() <= 0.000001:
		return

	var bullet_node_variant: Variant = PlayerBulletScene.instantiate()
	if not (bullet_node_variant is Node2D):
		return
	var bullet: Node2D = bullet_node_variant as Node2D
	if bullet == null:
		return

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	if scene_root != null:
		scene_root.add_child(bullet)
		bullet.global_position = global_position + _cached_brown_centroid_offset_px
		bullet.z_index = 20
		if bullet.has_method("setup_direction"):
			bullet.call("setup_direction", direction, bullet_speed_px)
			if _has_property(bullet, "damage"):
				bullet.set("damage", bullet_damage)
		_fire_cooldown_sec = fire_interval_sec


func _compute_fire_direction(target_enemy: Node2D) -> Vector2:
	var to_target: Vector2 = target_enemy.global_position - global_position
	if to_target.length_squared() <= 0.000001:
		return Vector2.ZERO
	var speed: float = maxf(bullet_speed_px, 1.0)
	var target_velocity: Vector2 = _get_target_velocity(target_enemy)
	var lead_time: float = to_target.length() / speed
	var predicted_position: Vector2 = target_enemy.global_position + target_velocity * lead_time
	var predicted_vector: Vector2 = predicted_position - global_position
	if predicted_vector.length_squared() <= 0.000001:
		return to_target.normalized()
	return predicted_vector.normalized()


func _get_target_velocity(target_enemy: Node2D) -> Vector2:
	var velocity_variant: Variant = target_enemy.get("velocity")
	if velocity_variant is Vector2:
		return velocity_variant as Vector2
	var linear_velocity_variant: Variant = target_enemy.get("linear_velocity")
	if linear_velocity_variant is Vector2:
		return linear_velocity_variant as Vector2
	return Vector2.ZERO


func _compute_brown_centroid_offset(image: Image, base_centroid: Vector2) -> Vector2:
	if image == null or image.is_empty():
		return Vector2.ZERO
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	for y in range(height):
		for x in range(width):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a < COLLISION_ALPHA_THRESHOLD:
				continue
			if not _is_brown_pixel(pixel):
				continue
			sum_x += float(x) + 0.5
			sum_y += float(y) + 0.5
			count += 1
	if count <= 0:
		return Vector2.ZERO
	var brown_centroid := Vector2(sum_x / float(count), sum_y / float(count))
	return brown_centroid - base_centroid


func _is_brown_pixel(pixel: Color) -> bool:
	var hsv_h: float = pixel.h
	var hsv_s: float = pixel.s
	var hsv_v: float = pixel.v
	return hsv_h >= 0.04 and hsv_h <= 0.14 and hsv_s >= 0.25 and hsv_v >= 0.12 and hsv_v <= 0.75


func _has_property(node: Object, property_name: String) -> bool:
	var properties: Array[Dictionary] = node.get_property_list()
	for property_info: Dictionary in properties:
		var name_variant: Variant = property_info.get("name", "")
		if name_variant is String and String(name_variant) == property_name:
			return true
	return false
