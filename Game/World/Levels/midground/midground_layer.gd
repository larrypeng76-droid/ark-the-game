extends Node2D

@export_range(0.0, 1.0, 0.01) var parallax_factor: float = 0.85
@export_range(0.0, 400.0, 1.0) var floor_clearance_pixels: float = 18.0
@export_range(-400.0, 400.0, 1.0) var y_offset_pixels: float = 0.0
@export var fit_to_viewport: bool = true
@export_range(0.1, 1.0, 0.01) var viewport_fit_ratio: float = 0.92
@export_range(0.1, 8.0, 0.1) var scale_multiplier: float = 4.0
@export var texture_override: Texture2D

@onready var visual_a: Sprite2D = $VisualA
@onready var visual_b: Sprite2D = $VisualB
@onready var visual_c: Sprite2D = $VisualC

var _player: Node2D
var _ground: Node
var _origin_x: float = 0.0


func _ready() -> void:
	_origin_x = global_position.x
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_ground = get_tree().get_first_node_in_group("diggable_ground")
	_apply_texture_override()
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
		_update_tile_positions()

	if not force_y and _ground == null:
		return
	if _ground == null or not _ground.has_method("get_grass_surface_world_y"):
		return

	var grass_y_variant: Variant = _ground.call("get_grass_surface_world_y")
	if not (grass_y_variant is float or grass_y_variant is int):
		return

	var grass_y: float = float(grass_y_variant)
	var tex_h: float = 0.0
	if visual_a != null and visual_a.texture != null:
		tex_h = visual_a.texture.get_size().y * visual_a.scale.y
	# Visuals are top-left anchored (centered=false): place bottom edge above grass.
	global_position.y = grass_y - floor_clearance_pixels - tex_h + y_offset_pixels


func _apply_texture_override() -> void:
	if texture_override == null:
		return
	if visual_a != null:
		visual_a.texture = texture_override
	if visual_b != null:
		visual_b.texture = texture_override
	if visual_c != null:
		visual_c.texture = texture_override


func _apply_viewport_fit_scale() -> void:
	if not fit_to_viewport:
		return
	if visual_a == null or visual_a.texture == null:
		return
	if scale_multiplier <= 0.0:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var tex_size: Vector2 = visual_a.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var target_scale: float = minf(
		(viewport_size.x * viewport_fit_ratio) / tex_size.x,
		(viewport_size.y * viewport_fit_ratio) / tex_size.y
	)
	target_scale = minf(target_scale, 1.0) * scale_multiplier
	var s := Vector2(target_scale, target_scale)
	visual_a.scale = s
	if visual_b != null:
		visual_b.scale = s
	if visual_c != null:
		visual_c.scale = s


func _update_tile_positions() -> void:
	if _player == null or visual_a == null or visual_b == null or visual_c == null:
		return
	if visual_a.texture == null:
		return

	var tile_w: float = visual_a.texture.get_size().x * visual_a.scale.x
	if tile_w <= 0.0:
		return

	# Keep tiles on both sides of the player/camera so it appears to extend infinitely
	# both forward and backward.
	var camera_x: float = _player.global_position.x
	var base_tile: float = floor((camera_x - global_position.x) / tile_w) * tile_w
	visual_c.position = Vector2(base_tile - tile_w, 0.0)
	visual_a.position = Vector2(base_tile, 0.0)
	visual_b.position = Vector2(base_tile + tile_w, 0.0)
