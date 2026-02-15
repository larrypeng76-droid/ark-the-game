extends Node2D

@export_range(0.0, 1.0, 0.01) var parallax_factor: float = 1.0
@export_range(0.0, 400.0, 1.0) var floor_clearance_pixels: float = 18.0
@export_range(-400.0, 400.0, 1.0) var y_offset_pixels: float = 25.0
@export var fit_to_viewport: bool = true
@export_range(0.1, 1.0, 0.01) var viewport_fit_ratio: float = 0.92

@onready var visual: Sprite2D = $Visual

var _player: Node2D
var _ground: Node
var _origin_x: float = 0.0


func _ready() -> void:
	_origin_x = global_position.x
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_ground = get_tree().get_first_node_in_group("diggable_ground")
	_apply_viewport_fit_scale()
	_update_position(true)


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _ground == null:
		_ground = get_tree().get_first_node_in_group("diggable_ground")
	_apply_viewport_fit_scale()
	_update_position(false)


func _update_position(force_y: bool) -> void:
	if _player != null:
		global_position.x = _origin_x + _player.global_position.x * parallax_factor

	if not force_y and _ground == null:
		return
	if _ground == null or not _ground.has_method("get_grass_surface_world_y"):
		return

	var grass_y_variant: Variant = _ground.call("get_grass_surface_world_y")
	if not (grass_y_variant is float or grass_y_variant is int):
		return

	var grass_y: float = float(grass_y_variant)
	var tex_h: float = 0.0
	if visual != null and visual.texture != null:
		tex_h = visual.texture.get_size().y * visual.scale.y
	global_position.y = grass_y - floor_clearance_pixels - tex_h * 0.5 + y_offset_pixels


func _apply_viewport_fit_scale() -> void:
	if not fit_to_viewport:
		return
	if visual == null or visual.texture == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var tex_size: Vector2 = visual.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var target_scale: float = minf(
		(viewport_size.x * viewport_fit_ratio) / tex_size.x,
		(viewport_size.y * viewport_fit_ratio) / tex_size.y
	)
	target_scale = minf(target_scale, 1.0)
	visual.scale = Vector2(target_scale, target_scale)
