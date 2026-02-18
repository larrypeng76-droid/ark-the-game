extends Node2D

var _grid_visible: bool = false
var _block_size_px: float = 10.0
var _ground_origin_global: Vector2 = Vector2.ZERO
var _grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.4)
var _grid_line_width_px: float = 1.0 / 3.0
var _dash_length_px: float = 5.0
var _dash_gap_px: float = 3.0
var _focus_center_global: Vector2 = Vector2.ZERO
var _focus_size_px: Vector2 = Vector2(75.0, 90.0)


func _ready() -> void:
	top_level = true
	z_as_relative = false
	z_index = 4000
	set_process(true)
	visible = false


func _process(_delta: float) -> void:
	if not _grid_visible:
		return
	queue_redraw()


func configure_grid(
	block_size_px: float,
	ground_origin_global: Vector2,
	line_color: Color,
	line_width_px: float,
	focus_center_global: Vector2,
	focus_size_px: Vector2
) -> void:
	_block_size_px = maxf(block_size_px, 1.0)
	_ground_origin_global = ground_origin_global
	_grid_line_color = line_color
	_grid_line_width_px = maxf(line_width_px, 0.1)
	_dash_length_px = maxf(_block_size_px * 0.35, 2.0)
	_dash_gap_px = maxf(_block_size_px * 0.2, 1.0)
	_focus_center_global = focus_center_global
	_focus_size_px = Vector2(
		maxf(focus_size_px.x, _block_size_px),
		maxf(focus_size_px.y, _block_size_px)
	)
	if _grid_visible:
		queue_redraw()


func set_grid_visible(active: bool) -> void:
	_grid_visible = active
	visible = active
	if active:
		queue_redraw()


func _draw() -> void:
	if not _grid_visible:
		return
	var world_rect: Rect2 = _get_focus_world_rect()
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return

	var min_x: float = world_rect.position.x
	var min_y: float = world_rect.position.y
	var max_x: float = world_rect.position.x + world_rect.size.x
	var max_y: float = world_rect.position.y + world_rect.size.y

	var start_x: float = _snap_to_grid_down(min_x, _ground_origin_global.x, _block_size_px)
	var start_y: float = _snap_to_grid_down(min_y, _ground_origin_global.y, _block_size_px)

	var x: float = start_x
	while x <= max_x:
		_draw_dashed_line(
			Vector2(x, min_y),
			Vector2(x, max_y),
			_grid_line_color,
			_grid_line_width_px,
			_dash_length_px,
			_dash_gap_px
		)
		x += _block_size_px

	var y: float = start_y
	while y <= max_y:
		_draw_dashed_line(
			Vector2(min_x, y),
			Vector2(max_x, y),
			_grid_line_color,
			_grid_line_width_px,
			_dash_length_px,
			_dash_gap_px
		)
		y += _block_size_px


func _draw_dashed_line(
	from: Vector2,
	to: Vector2,
	color: Color,
	width_px: float,
	dash_length_px: float,
	gap_length_px: float
) -> void:
	var segment_delta: Vector2 = to - from
	var total_length: float = segment_delta.length()
	if total_length <= 0.0:
		return

	var direction: Vector2 = segment_delta / total_length
	var cursor: float = 0.0
	while cursor < total_length:
		var dash_start: Vector2 = from + direction * cursor
		var dash_end_distance: float = minf(cursor + dash_length_px, total_length)
		var dash_end: Vector2 = from + direction * dash_end_distance
		draw_line(dash_start, dash_end, color, width_px, true)
		cursor += dash_length_px + gap_length_px


func _snap_to_grid_down(value: float, grid_origin: float, step: float) -> float:
	return grid_origin + floor((value - grid_origin) / step) * step


func _get_focus_world_rect() -> Rect2:
	var half_size: Vector2 = _focus_size_px * 0.5
	var top_left: Vector2 = _focus_center_global - half_size
	return Rect2(top_left, _focus_size_px)
