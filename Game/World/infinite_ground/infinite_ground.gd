# res://game/world/infinite_ground/infinite_ground.gd

extends Node2D

const GROUND_TEXTURE := preload("res://game/world/assets/tilemaps/Tilemap-Sides-Grass.png")
const GroundBlockDropScene := preload("res://game/features/items/ground_block/ground_block_drop.tscn")
const WoodDropScene := preload("res://game/features/items/wood/wood_drop.tscn")
const BigTreeFeatherShader := preload("res://game/world/infinite_ground/big_tree_feather.gdshader")
const SproutEdgeFeatherShader := preload("res://game/world/infinite_ground/sprout_edge_feather.gdshader")
const PAINTING_SPROUT_RANDOM_TEXTURE_PATHS: Array[String] = [
	"res://game/world/assets/sprouts/painting_17.png",
	"res://game/world/assets/sprouts/painting_18.png",
]

@export_group("Generation")
@export_range(8, 256, 1) var block_size: int = 10
@export var ground_top_block_y: int = 27
@export_range(1, 256, 1) var ground_depth_blocks: int = 20
@export_range(1, 1024, 1) var vertical_ahead_blocks: int = 120

@export_group("Streaming")
@export_range(8, 1024, 1) var half_width_blocks: int = 64
@export_range(0, 4096, 1) var trim_padding_blocks: int = 96

@export_group("Placement Fall")
@export_range(50.0, 6000.0, 10.0) var placed_block_fall_gravity: float = 1800.0
@export_range(50.0, 6000.0, 10.0) var placed_block_fall_max_speed: float = 2200.0
@export_range(0.0, 6.0, 0.1) var placed_block_contact_tolerance_px: float = 1.0

@export_group("Visual")
@export var ground_tile_region: Rect2i = Rect2i(16, 16, 16, 16)
@export var block_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var grass_top_color: Color = Color(0.31, 0.73, 0.31, 1.0)
@export var grass_mid_color: Color = Color(0.22, 0.58, 0.20, 1.0)
@export var dirt_color: Color = Color(0.27, 0.18, 0.12, 1.0)
@export var grass_cap_texture_override: Texture2D
@export var grass_cap_use_strip_sampling: bool = true

@export_group("Floor Cycle (Layer 1)")
@export var floor_cycle_enabled: bool = true
@export var floor_cycle_count: int = 22
@export var floor_cycle_offset: int = 0
@export var floor_cycle_path_format: String = "res://game/world/assets/floor_cycles/img_1735/img_1735_%d.jpg"
@export var floor_cycle_tile_size_px: Vector2i = Vector2i(10, 8) # width (base) x height
@export var floor_cycle_visual_offset_px: Vector2 = Vector2(0.0, 2.0)
@export var floor_cycle_top_line_enabled: bool = true
@export_range(1, 10, 1) var floor_cycle_top_line_height_px: int = 1
@export var floor_cycle_top_line_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export_range(0.0, 1.0, 0.01) var floor_cycle_top_line_edge_alpha: float = 0.06
@export_range(0.05, 1.0, 0.01) var floor_cycle_top_line_thickness: float = 0.45

@export_group("Trees")
@export_range(0.0, 1.0, 0.01) var tree_density: float = 0.18
@export_range(0.0, 1.0, 0.01) var big_tree_ratio: float = 0.35
@export var tree_seed: int = 1337
@export var small_tree_texture: Texture2D
@export var small_tree_texture_scale: Vector2 = Vector2(0.12, 0.12)
@export var small_tree_texture_offset: Vector2 = Vector2(0.0, 0.0)
@export var big_tree_texture: Texture2D
@export var big_tree_texture_scale: Vector2 = Vector2(0.11, 0.11)
@export var big_tree_texture_offset: Vector2 = Vector2(0.0, 0.0)
@export_range(1, 99, 1) var small_tree_hits_required: int = 10
@export_range(1, 99, 1) var big_tree_hits_required: int = 15
@export var small_tree_canopy_color: Color = Color(0.23, 0.53, 0.22, 1.0)
@export var big_tree_canopy_color: Color = Color(0.19, 0.45, 0.19, 1.0)
@export var tree_trunk_color: Color = Color(0.34, 0.23, 0.13, 1.0)
@export_range(-4096, 4096, 1) var big_tree_z_index: int = 50
@export_range(0.0, 32.0, 0.1) var big_tree_edge_feather_px: float = 2.0
@export_range(0.0, 1.0, 0.01) var big_tree_edge_alpha_multiplier: float = 1.0

@export_group("Grass Sprouts")
@export var grass_sprouts_enabled: bool = true
# Probability per column to spawn a small decorative grass tuft. Keep low to avoid clutter.
@export_range(0.0, 1.0, 0.01) var grass_sprouts_density: float = 0.10
@export var grass_sprouts_texture: Texture2D
@export_range(-180.0, 180.0, 1.0) var grass_sprouts_texture_rotation_degrees: float = -90.0
@export_range(0.2, 6.0, 0.05) var grass_sprouts_texture_width_blocks_min: float = 0.8
@export_range(0.2, 8.0, 0.05) var grass_sprouts_texture_width_blocks_max: float = 1.4
@export_range(0.2, 8.0, 0.05) var grass_sprouts_texture_height_blocks_min: float = 0.9
@export_range(0.2, 10.0, 0.05) var grass_sprouts_texture_height_blocks_max: float = 1.8
@export_range(1, 8, 1) var grass_sprouts_blades_min: int = 3
@export_range(1, 12, 1) var grass_sprouts_blades_max: int = 5
@export var grass_sprouts_color: Color = Color(0.19, 0.62, 0.20, 1.0)
@export_range(0.0, 0.5, 0.01) var grass_sprouts_color_variation: float = 0.10
@export_range(0.5, 5.0, 0.1) var grass_sprouts_line_width: float = 1.2
@export_range(0.05, 2.0, 0.01) var grass_sprouts_height_blocks_min: float = 0.35
@export_range(0.05, 3.0, 0.01) var grass_sprouts_height_blocks_max: float = 0.85
@export_range(0.0, 1.0, 0.01) var grass_sprouts_horizontal_jitter_blocks: float = 0.35

@export_group("Painting Sprouts")
@export var painting_sprouts_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var painting_sprouts_density: float = 0.04
@export var painting_sprouts_texture: Texture2D
@export_range(0.2, 8.0, 0.05) var painting_sprouts_width_blocks: float = 1.0
@export_range(0.5, 20.0, 0.1) var painting_sprouts_height_blocks: float = 10.0
@export_range(1.0, 512.0, 1.0) var painting_sprouts_height_px_min: float = 18.0
@export_range(1.0, 512.0, 1.0) var painting_sprouts_height_px_max: float = 25.0
@export_range(-200.0, 200.0, 1.0) var painting_sprouts_vertical_offset_px: float = 0.0
@export_range(1, 32, 1) var painting_sprouts_instances_per_column: int = 1
@export_range(0.0, 2.0, 0.01) var painting_sprouts_horizontal_jitter_blocks: float = 0.35
@export_range(0.0, 0.95, 0.01) var painting_sprouts_max_overlap_ratio: float = 0.15
@export_range(0.0, 8.0, 0.1) var painting_sprouts_edge_feather_px: float = 1.5
@export_range(0.0, 1.0, 0.01) var painting_sprouts_alpha_multiplier: float = 0.92
@export_range(-90.0, 0.0, 1.0) var painting_sprouts_swing_min_degrees: float = -10.0
@export_range(0.0, 90.0, 1.0) var painting_sprouts_swing_max_degrees: float = 10.0
@export_range(0.05, 4.0, 0.05) var painting_sprouts_swing_speed: float = 1.2

const PLAYER_GROUP_NAME := "player"
const DIGGABLE_GROUND_GROUP := "diggable_ground"
const TERRAIN_LAYER_BIT: int = 1 << 2
const ANY_COLLISION_MASK: int = -1

var generated_min_x: int = 0
var generated_max_x: int = -1
var generated_max_y: int = -1
var last_player_block_x: int = 2147483647
var last_player_block_y: int = 2147483647
var player: Node2D

var blocks_root: Node2D
var trees_root: Node2D
var grass_sprouts_root: Node2D
var painting_sprouts_root: Node2D
var _active_blocks: Dictionary = {}
var _dug_blocks: Dictionary = {}
var _active_trees: Dictionary = {}
var _active_grass_sprouts: Dictionary = {}
var _active_painting_sprouts: Dictionary = {}
var _tree_protected_cells: Dictionary = {}
var _falling_blocks: Array[Dictionary] = []
var _falling_target_cells: Dictionary = {}
var _custom_grass_texture: Texture2D
var _floor_cycle_textures: Array[Texture2D] = []
var _floor_top_line_texture: Texture2D
var _painting_sprout_material: ShaderMaterial
var _painting_sprout_random_textures: Array[Texture2D] = []


func _ready() -> void:
	add_to_group(DIGGABLE_GROUND_GROUP)
	blocks_root = Node2D.new()
	blocks_root.name = "Blocks"
	add_child(blocks_root)
	trees_root = Node2D.new()
	trees_root.name = "Trees"
	add_child(trees_root)
	grass_sprouts_root = Node2D.new()
	grass_sprouts_root.name = "GrassSprouts"
	add_child(grass_sprouts_root)
	painting_sprouts_root = Node2D.new()
	painting_sprouts_root.name = "PaintingSprouts"
	add_child(painting_sprouts_root)
	# Optional override so the grass cap can use custom art instead of the procedural texture.
	_custom_grass_texture = grass_cap_texture_override if grass_cap_texture_override != null else _create_custom_grass_texture()
	_floor_cycle_textures = _load_floor_cycle_textures()
	_floor_top_line_texture = _create_top_line_texture() if floor_cycle_top_line_enabled else null
	_painting_sprout_material = _create_painting_sprout_material()
	_painting_sprout_random_textures = _load_painting_sprout_random_textures()

	_try_find_player()
	if player != null:
		_update_around_player(true)


func _process(delta: float) -> void:
	_update_painting_sprout_sway(delta)
	_update_falling_blocks(delta)
	if player == null:
		_try_find_player()
		if player == null:
			return
		_update_around_player(true)
		return

	_update_around_player()


func dig_at(target_global_position: Vector2, radius: float) -> int:
	if radius <= 0.0:
		return 0

	var local_center: Vector2 = to_local(target_global_position)
	var min_corner: Vector2 = local_center - Vector2(radius, radius)
	var max_corner: Vector2 = local_center + Vector2(radius, radius)
	var min_cell: Vector2i = _world_to_block(min_corner)
	var max_cell: Vector2i = _world_to_block(max_corner)

	var removed_count: int = 0
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			if not _active_blocks.has(cell):
				continue
			if _is_tree_protected_cell(cell):
				continue
			if not _circle_overlaps_block(local_center, radius, cell):
				continue
			_remove_block(cell, true)
			removed_count += 1

	return removed_count


func chop_trees_at(target_global_position: Vector2, radius: float) -> int:
	if radius <= 0.0:
		return 0

	var local_center: Vector2 = to_local(target_global_position)
	var min_corner: Vector2 = local_center - Vector2(radius, radius)
	var max_corner: Vector2 = local_center + Vector2(radius, radius)
	var min_cell: Vector2i = _world_to_block(min_corner)
	var max_cell: Vector2i = _world_to_block(max_corner)

	var best_tree: Node2D
	var best_column_x: int = 0
	var best_distance_sq: float = INF
	for x in range(min_cell.x, max_cell.x + 1):
		if not _active_trees.has(x):
			continue
		var tree_node: Node2D = _active_trees[x] as Node2D
		if tree_node == null:
			continue

		var center_offset_variant: Variant = tree_node.get_meta("chop_center_offset", Vector2(0.0, 0.0))
		var center_offset: Vector2 = center_offset_variant as Vector2 if center_offset_variant is Vector2 else Vector2.ZERO
		var chop_radius_variant: Variant = tree_node.get_meta("chop_radius", float(block_size) * 2.0)
		var chop_radius: float = float(chop_radius_variant)

		var target_center: Vector2 = tree_node.position + center_offset
		var max_distance: float = radius + chop_radius
		var distance_sq: float = local_center.distance_squared_to(target_center)
		if distance_sq > max_distance * max_distance:
			continue

		if distance_sq < best_distance_sq:
			best_distance_sq = distance_sq
			best_tree = tree_node
			best_column_x = x
	if best_tree == null:
		return 0
	_damage_tree(best_column_x, best_tree)
	return 1


func place_ground_block_at_world(target_global_position: Vector2) -> bool:
	var local_position: Vector2 = to_local(target_global_position)
	var cell: Vector2i = _world_to_block(local_position)
	if _active_blocks.has(cell):
		return false
	if _falling_target_cells.has(cell):
		return false
	if _is_tree_protected_cell(cell):
		return false

	var base_max_y: int = ground_top_block_y + ground_depth_blocks - 1
	var desired_max_y: int = maxi(base_max_y, cell.y + vertical_ahead_blocks)
	_ensure_generated_range(cell.x, cell.x, desired_max_y)

	var settled_cell: Vector2i = cell
	while settled_cell.y < generated_max_y:
		if _is_cell_supported_for_placed_block(settled_cell):
			break
		settled_cell += Vector2i(0, 1)

	if _is_tree_protected_cell(settled_cell):
		return false
	if _active_blocks.has(settled_cell):
		return false
	if _falling_target_cells.has(settled_cell):
		return false

	if settled_cell == cell:
		_dug_blocks.erase(settled_cell)
		_create_ground_block(settled_cell)
		return true

	_spawn_falling_ground_block(cell, settled_cell)
	return true


func _get_grass_cap_y() -> int:
	return ground_top_block_y - 1


func get_grass_surface_world_y() -> float:
	var grass_top_local_y: float = float(_get_grass_cap_y() * block_size)
	return to_global(Vector2(0.0, grass_top_local_y)).y


func _try_find_player() -> void:
	player = get_tree().get_first_node_in_group(PLAYER_GROUP_NAME) as Node2D


func _update_around_player(force: bool = false) -> void:
	var player_local: Vector2 = to_local(player.global_position)
	var player_cell: Vector2i = _world_to_block(player_local)
	var player_cell_x: int = player_cell.x
	var player_cell_y: int = player_cell.y
	if not force and player_cell_x == last_player_block_x and player_cell_y == last_player_block_y:
		return

	last_player_block_x = player_cell_x
	last_player_block_y = player_cell_y

	var desired_min_x: int = player_cell_x - half_width_blocks
	var desired_max_x: int = player_cell_x + half_width_blocks
	var base_max_y: int = ground_top_block_y + ground_depth_blocks - 1
	var desired_max_y: int = maxi(base_max_y, player_cell_y + vertical_ahead_blocks)
	_ensure_generated_range(desired_min_x, desired_max_x, desired_max_y)


func _ensure_generated_range(desired_min_x: int, desired_max_x: int, desired_max_y: int) -> void:
	var base_max_y: int = ground_top_block_y + ground_depth_blocks - 1
	var target_max_y: int = maxi(base_max_y, desired_max_y)

	if generated_max_x < generated_min_x:
		generated_min_x = desired_min_x
		generated_max_x = desired_max_x
		generated_max_y = target_max_y
		_generate_rect(desired_min_x, desired_max_x, ground_top_block_y, generated_max_y)
	elif desired_min_x < generated_min_x:
		_generate_rect(desired_min_x, generated_min_x - 1, ground_top_block_y, target_max_y)
		generated_min_x = desired_min_x

	if desired_max_x > generated_max_x:
		_generate_rect(generated_max_x + 1, desired_max_x, ground_top_block_y, target_max_y)
		generated_max_x = desired_max_x

	if generated_max_y < ground_top_block_y:
		generated_max_y = base_max_y

	if target_max_y > generated_max_y:
		_generate_rect(generated_min_x, generated_max_x, generated_max_y + 1, target_max_y)
		generated_max_y = target_max_y

	if trim_padding_blocks > 0:
		var trim_min_x: int = desired_min_x - trim_padding_blocks
		var trim_max_x: int = desired_max_x + trim_padding_blocks
		_trim_outside_range(trim_min_x, trim_max_x)


func _generate_rect(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	if min_x > max_x or min_y > max_y:
		return

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var cell := Vector2i(x, y)
			if _dug_blocks.has(cell):
				continue
			if _active_blocks.has(cell):
				continue
			if _falling_target_cells.has(cell):
				continue
			_create_ground_block(cell)

	var grass_y: int = _get_grass_cap_y()
	if grass_y > max_y:
		return
	for x in range(min_x, max_x + 1):
		var grass_cell := Vector2i(x, grass_y)
		if _dug_blocks.has(grass_cell):
			continue
		if _active_blocks.has(grass_cell):
			continue
		_create_grass_cap_block(grass_cell)
		_try_spawn_tree_on_grass_cell(grass_cell)
		_try_spawn_grass_sprouts_on_grass_cell(grass_cell)
		_try_spawn_painting_sprouts_on_grass_cell(grass_cell)



func _create_ground_block(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.name = "Block_%d_%d" % [cell.x, cell.y]
	body.position = _block_center_world(cell)
	body.collision_layer = TERRAIN_LAYER_BIT
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(float(block_size), float(block_size))
	shape.shape = rectangle
	body.add_child(shape)

	body.add_child(_create_block_sprite(ground_tile_region))

	blocks_root.add_child(body)
	_active_blocks[cell] = body


func _create_grass_cap_block(cell: Vector2i) -> void:
	var node := StaticBody2D.new()
	node.name = "GrassCap_%d_%d" % [cell.x, cell.y]
	node.position = _block_center_world(cell)
	node.collision_layer = TERRAIN_LAYER_BIT
	node.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(float(block_size), float(block_size))
	shape.shape = rectangle
	node.add_child(shape)

	if floor_cycle_enabled and not _floor_cycle_textures.is_empty():
		shape.position = floor_cycle_visual_offset_px
		node.add_child(_create_floor_cycle_sprite(cell))
		if floor_cycle_top_line_enabled:
			node.add_child(_create_floor_cycle_top_line_sprite())
		blocks_root.add_child(node)
		_active_blocks[cell] = node
		return

	var visual := Sprite2D.new()
	visual.centered = true
	visual.texture = _custom_grass_texture
	if _custom_grass_texture != null and grass_cap_texture_override != null and grass_cap_use_strip_sampling:
		# Use contiguous source sampling so neighboring grass-cap blocks visually connect.
		var tex_size: Vector2 = _custom_grass_texture.get_size()
		var tex_w: int = maxi(int(tex_size.x), block_size)
		var tex_h: int = maxi(int(tex_size.y), block_size)
		var max_x_start: int = maxi(tex_w - block_size, 0)
		var x_start: int = 0
		if max_x_start > 0:
			x_start = posmod(cell.x * block_size, max_x_start + 1)
		visual.region_enabled = true
		visual.region_rect = Rect2(float(x_start), 0.0, float(block_size), float(block_size))
	elif _custom_grass_texture != null:
		var tex_size_fallback: Vector2 = _custom_grass_texture.get_size()
		if tex_size_fallback.x > 0.0 and tex_size_fallback.y > 0.0:
			visual.region_enabled = false
			visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			visual.scale = Vector2(float(block_size) / tex_size_fallback.x, float(block_size) / tex_size_fallback.y)
	node.add_child(visual)
	blocks_root.add_child(node)
	_active_blocks[cell] = node


func _try_spawn_tree_on_grass_cell(grass_cell: Vector2i) -> void:
	if _active_trees.has(grass_cell.x):
		return
	if _column_random01(grass_cell.x, 1) > clampf(tree_density, 0.0, 1.0):
		return

	var is_big_tree: bool = _column_random01(grass_cell.x, 2) < clampf(big_tree_ratio, 0.0, 1.0)
	if not is_big_tree:
		return
	var tree := _create_tree_node(grass_cell, is_big_tree)
	if tree == null:
		return
	trees_root.add_child(tree)
	_active_trees[grass_cell.x] = tree
	_set_tree_protected_cell(grass_cell, true)
	_set_tree_protected_cell(grass_cell + Vector2i(0, 1), true)

func _try_spawn_grass_sprouts_on_grass_cell(grass_cell: Vector2i) -> void:
	if not grass_sprouts_enabled:
		return
	var column_x: int = grass_cell.x
	if _active_grass_sprouts.has(column_x):
		return
	# Avoid placing tufts under trees to keep the surface readable.
	if _active_trees.has(column_x):
		return
	if _column_random01(column_x, 101) > clampf(grass_sprouts_density, 0.0, 1.0):
		return

	var sprouts: Node2D = _create_grass_sprouts_node(grass_cell)
	if sprouts == null:
		return
	grass_sprouts_root.add_child(sprouts)
	_active_grass_sprouts[column_x] = sprouts

func _try_spawn_painting_sprouts_on_grass_cell(grass_cell: Vector2i) -> void:
	if not painting_sprouts_enabled:
		return
	if painting_sprouts_texture == null and _painting_sprout_random_textures.is_empty():
		return
	var column_x: int = grass_cell.x
	if _active_painting_sprouts.has(column_x):
		return
	if _active_trees.has(column_x):
		return
	if _column_random01(column_x, 301) > clampf(painting_sprouts_density, 0.0, 1.0):
		return

	var nodes: Array[Node2D] = []
	var count: int = maxi(1, painting_sprouts_instances_per_column)
	var target_w: float = float(block_size) * maxf(0.2, painting_sprouts_width_blocks)
	var overlap_ratio: float = clampf(painting_sprouts_max_overlap_ratio, 0.0, 0.95)
	var min_separation_px: float = target_w * (1.0 - overlap_ratio)
	var jitter_px: float = float(block_size) * maxf(0.0, painting_sprouts_horizontal_jitter_blocks)
	var offsets: Array[float] = _generate_painting_sprout_offsets(column_x, count, jitter_px, min_separation_px)
	for i in range(offsets.size()):
		var x_offset: float = offsets[i]
		var node: Node2D = _create_painting_sprouts_node(grass_cell, x_offset, i)
		if node == null:
			continue
		painting_sprouts_root.add_child(node)
		nodes.append(node)
	if nodes.is_empty():
		return
	_active_painting_sprouts[column_x] = nodes

func _create_painting_sprouts_node(grass_cell: Vector2i, x_offset_px: float, index_in_column: int) -> Node2D:
	var column_x: int = grass_cell.x
	var sprout_texture: Texture2D = _pick_painting_sprout_texture(column_x, index_in_column)
	if sprout_texture == null:
		return null
	var node := Node2D.new()
	node.name = "PaintingSprout_%d_%d" % [column_x, index_in_column]

	var base_x: float = (float(column_x) + 0.5) * float(block_size)
	var surface_y: float = float(grass_cell.y * block_size)
	node.position = Vector2(base_x + x_offset_px, surface_y + painting_sprouts_vertical_offset_px)

	var sprite := Sprite2D.new()
	sprite.texture = sprout_texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 2
	if _painting_sprout_material != null:
		sprite.material = _painting_sprout_material

	var tex_size: Vector2 = sprout_texture.get_size()
	var tex_w: float = maxf(tex_size.x, 1.0)
	var tex_h: float = maxf(tex_size.y, 1.0)
	var target_w: float = float(block_size) * maxf(0.2, painting_sprouts_width_blocks)
	var h_min_px: float = minf(painting_sprouts_height_px_min, painting_sprouts_height_px_max)
	var h_max_px: float = maxf(painting_sprouts_height_px_min, painting_sprouts_height_px_max)
	var h_rand_t: float = _column_random01(column_x, 305 + index_in_column * 11)
	var target_h: float = lerpf(h_min_px, h_max_px, h_rand_t)
	if target_h <= 0.0:
		target_h = float(block_size) * maxf(0.5, painting_sprouts_height_blocks)
	sprite.scale = Vector2(target_w / tex_w, target_h / tex_h)
	# Base of the image stays planted on the ground while parent node rotates.
	sprite.position = Vector2(0.0, -target_h * 0.5)
	node.add_child(sprite)

	var global_min_deg: float = minf(painting_sprouts_swing_min_degrees, painting_sprouts_swing_max_degrees)
	var global_max_deg: float = maxf(painting_sprouts_swing_min_degrees, painting_sprouts_swing_max_degrees)
	var min_pick_t: float = _column_random01(column_x, 302 + index_in_column * 11)
	var node_min_deg: float = lerpf(global_min_deg, global_max_deg, min_pick_t)
	var max_pick_t: float = _column_random01(column_x, 303 + index_in_column * 11)
	var node_max_deg: float = lerpf(node_min_deg, global_max_deg, max_pick_t)
	if node_max_deg - node_min_deg < 0.001:
		node_max_deg = minf(global_max_deg, node_min_deg + 0.1)

	# Random starting angle per sprout, then solve phase so sway continues smoothly.
	var start_t: float = _column_random01(column_x, 304 + index_in_column * 11)
	var start_deg: float = lerpf(node_min_deg, node_max_deg, start_t)
	node.rotation = deg_to_rad(start_deg)
	var sin_target: float = clampf(start_t * 2.0 - 1.0, -1.0, 1.0)
	var now_t: float = Time.get_ticks_msec() * 0.001 * painting_sprouts_swing_speed
	var phase: float = asin(sin_target) - now_t

	node.set_meta("sway_phase", phase)
	node.set_meta("sway_min_deg", node_min_deg)
	node.set_meta("sway_max_deg", node_max_deg)
	return node

func _pick_painting_sprout_texture(column_x: int, index_in_column: int) -> Texture2D:
	if not _painting_sprout_random_textures.is_empty():
		var pick_t: float = _column_random01(column_x, 306 + index_in_column * 11)
		var idx: int = clampi(int(floor(pick_t * float(_painting_sprout_random_textures.size()))), 0, _painting_sprout_random_textures.size() - 1)
		var tex: Texture2D = _painting_sprout_random_textures[idx]
		if tex != null:
			return tex
	return painting_sprouts_texture

func _load_painting_sprout_random_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path: String in PAINTING_SPROUT_RANDOM_TEXTURE_PATHS:
		if not FileAccess.file_exists(path):
			continue
		if FileAccess.file_exists(path + ".import"):
			var res: Resource = load(path)
			if res is Texture2D:
				textures.append(res as Texture2D)
				continue
		# Fallback for fresh PNGs without .import metadata yet.
		var img: Image = Image.load_from_file(path)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			if tex != null:
				textures.append(tex)
	return textures

func _create_painting_sprout_material() -> ShaderMaterial:
	if SproutEdgeFeatherShader == null:
		return null
	var mat := ShaderMaterial.new()
	mat.shader = SproutEdgeFeatherShader
	mat.set_shader_parameter("feather_px", maxf(0.0, painting_sprouts_edge_feather_px))
	mat.set_shader_parameter("alpha_multiplier", clampf(painting_sprouts_alpha_multiplier, 0.0, 1.0))
	return mat

func _generate_painting_sprout_offsets(column_x: int, count: int, jitter_px: float, min_separation_px: float) -> Array[float]:
	var offsets: Array[float] = []
	if count <= 0:
		return offsets

	var half_span: float = maxf(jitter_px, 0.0)
	if count > 1 and min_separation_px > 0.0:
		var required_half_span: float = float(count - 1) * min_separation_px * 0.5
		half_span = maxf(half_span, required_half_span)

	if count == 1:
		offsets.append(lerpf(-half_span, half_span, _column_random01(column_x, 320)))
		return offsets

	var total_span: float = float(count - 1) * min_separation_px
	var min_start: float = -half_span
	var max_start: float = half_span - total_span
	var start: float = lerpf(min_start, max_start, _column_random01(column_x, 321))
	for i in range(count):
		offsets.append(start + float(i) * min_separation_px)
	return offsets


func _create_grass_sprouts_node(grass_cell: Vector2i) -> Node2D:
	var column_x: int = grass_cell.x
	var node := Node2D.new()
	node.name = "Sprouts_%d" % column_x

	# Anchor to the top surface of the grass-cap block (local space).
	var base_x: float = (float(column_x) + 0.5) * float(block_size)
	var surface_y: float = float(grass_cell.y * block_size)
	node.position = Vector2(base_x, surface_y)

	var blades_min: int = maxi(1, grass_sprouts_blades_min)
	var blades_max: int = maxi(blades_min, grass_sprouts_blades_max)
	var blades_f: float = lerpf(float(blades_min), float(blades_max) + 0.999, _column_random01(column_x, 102))
	var blade_count: int = clampi(int(floor(blades_f)), blades_min, blades_max)

	var height_min_blocks: float = maxf(grass_sprouts_height_blocks_min, 0.01)
	var height_max_blocks: float = maxf(grass_sprouts_height_blocks_max, height_min_blocks)
	var jitter_px: float = float(block_size) * clampf(grass_sprouts_horizontal_jitter_blocks, 0.0, 1.0)
	var width_px: float = maxf(grass_sprouts_line_width, 0.5)
	var variation: float = clampf(grass_sprouts_color_variation, 0.0, 0.5)

	if grass_sprouts_texture != null:
		var sprite := Sprite2D.new()
		sprite.texture = grass_sprouts_texture
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

		var tex_size: Vector2 = grass_sprouts_texture.get_size()
		var tex_width: float = maxf(tex_size.x, 1.0)
		var tex_height: float = maxf(tex_size.y, 1.0)
		var width_blocks_min: float = maxf(0.2, grass_sprouts_texture_width_blocks_min)
		var width_blocks_max: float = maxf(width_blocks_min, grass_sprouts_texture_width_blocks_max)
		var height_blocks_min: float = maxf(0.2, grass_sprouts_texture_height_blocks_min)
		var height_blocks_max: float = maxf(height_blocks_min, grass_sprouts_texture_height_blocks_max)
		var width_blocks: float = lerpf(width_blocks_min, width_blocks_max, _column_random01(column_x, 201))
		var height_blocks: float = lerpf(height_blocks_min, height_blocks_max, _column_random01(column_x, 202))
		var target_width_px: float = float(block_size) * width_blocks
		var target_height_px: float = float(block_size) * height_blocks
		sprite.scale = Vector2(target_width_px / tex_width, target_height_px / tex_height)
		sprite.position = Vector2(lerpf(-jitter_px, jitter_px, _column_random01(column_x, 203)), -target_height_px * 0.5 + 5.0)
		sprite.rotation = deg_to_rad(grass_sprouts_texture_rotation_degrees)

		# Keep original texture colors (no tint/modulation).
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		node.add_child(sprite)
		return node

	for i in range(blade_count):
		var blade := Line2D.new()
		blade.name = "Blade_%d" % i
		blade.antialiased = true
		blade.width = width_px
		blade.round_precision = 6
		blade.begin_cap_mode = Line2D.LINE_CAP_ROUND
		blade.end_cap_mode = Line2D.LINE_CAP_ROUND

		var salt_base: int = 110 + i * 7
		var x_jitter: float = lerpf(-jitter_px, jitter_px, _column_random01(column_x, salt_base + 1))
		var height_px: float = float(block_size) * lerpf(height_min_blocks, height_max_blocks, _column_random01(column_x, salt_base + 2))
		var lean: float = lerpf(-0.65, 0.65, _column_random01(column_x, salt_base + 3))

		# Simple 3-point curve for a slight natural bend.
		var p0 := Vector2(x_jitter, 0.0)
		var p1 := Vector2(x_jitter + lean * height_px * 0.18, -height_px * 0.55)
		var p2 := Vector2(x_jitter + lean * height_px * 0.35, -height_px)
		blade.points = PackedVector2Array([p0, p1, p2])

		var v: float = lerpf(-variation, variation, _column_random01(column_x, salt_base + 4))
		blade.default_color = grass_sprouts_color.lightened(v) if v > 0.0 else grass_sprouts_color.darkened(-v)

		node.add_child(blade)

	return node


func _create_tree_node(grass_cell: Vector2i, is_big_tree: bool) -> Node2D:
	var tree := Node2D.new()
	tree.name = ("BigTree_%d" if is_big_tree else "SmallTree_%d") % grass_cell.x
	tree.position = Vector2(_block_center_world(grass_cell).x, float(grass_cell.y * block_size))
	if is_big_tree:
		tree.z_as_relative = false
		tree.z_index = big_tree_z_index
	tree.set_meta("hits_remaining", big_tree_hits_required if is_big_tree else small_tree_hits_required)

	if is_big_tree and big_tree_texture != null:
		var sprite := Sprite2D.new()
		var tex_size: Vector2 = big_tree_texture.get_size()
		var tree_height: float = tex_size.y * big_tree_texture_scale.y
		var tree_width: float = tex_size.x * big_tree_texture_scale.x
		sprite.texture = big_tree_texture
		sprite.centered = true
		_apply_big_tree_feather(sprite)
		sprite.scale = big_tree_texture_scale
		sprite.position = big_tree_texture_offset + Vector2(0.0, -tree_height * 0.5)
		tree.add_child(sprite)

		# Keep chop center around the trunk middle so axe clicks near the base still register.
		var chop_center_offset: Vector2 = Vector2(sprite.position.x, -tree_height * 0.38)
		var chop_radius: float = max(tree_width, tree_height) * 0.55
		tree.set_meta("chop_center_offset", chop_center_offset)
		tree.set_meta("chop_radius", max(chop_radius, float(block_size) * 3.6))
		return tree

	if not is_big_tree and small_tree_texture != null:
		var sprite := Sprite2D.new()
		var tex_size: Vector2 = small_tree_texture.get_size()
		sprite.texture = small_tree_texture
		sprite.centered = true
		sprite.scale = small_tree_texture_scale
		sprite.position = small_tree_texture_offset + Vector2(0.0, -tex_size.y * small_tree_texture_scale.y * 0.5)
		tree.add_child(sprite)

		var chop_center_offset: Vector2 = sprite.position + Vector2(0.0, -tex_size.y * small_tree_texture_scale.y * 0.2)
		var chop_radius: float = max(tex_size.x * small_tree_texture_scale.x, tex_size.y * small_tree_texture_scale.y) * 0.35
		tree.set_meta("chop_center_offset", chop_center_offset)
		tree.set_meta("chop_radius", max(chop_radius, float(block_size) * 1.6))
		return tree

	var trunk_height_blocks: float = 5.0 if is_big_tree else 3.0
	var trunk_width_blocks: float = 1.1 if is_big_tree else 0.8
	var trunk_height: float = float(block_size) * trunk_height_blocks
	var trunk_width: float = float(block_size) * trunk_width_blocks

	var trunk := Polygon2D.new()
	trunk.color = tree_trunk_color
	trunk.polygon = PackedVector2Array([
		Vector2(-trunk_width * 0.5, 0.0),
		Vector2(trunk_width * 0.5, 0.0),
		Vector2(trunk_width * 0.5, -trunk_height),
		Vector2(-trunk_width * 0.5, -trunk_height),
	])
	tree.add_child(trunk)

	var canopy_radius: float = float(block_size) * (2.4 if is_big_tree else 1.6)
	var canopy_center_y: float = -trunk_height - canopy_radius * 0.15

	var canopy := Polygon2D.new()
	canopy.color = big_tree_canopy_color if is_big_tree else small_tree_canopy_color
	canopy.polygon = _create_tree_canopy_polygon(canopy_radius, Vector2(0.0, canopy_center_y))
	tree.add_child(canopy)

	if is_big_tree:
		var canopy_back := Polygon2D.new()
		canopy_back.color = big_tree_canopy_color.darkened(0.08)
		canopy_back.polygon = _create_tree_canopy_polygon(canopy_radius * 0.78, Vector2(-canopy_radius * 0.6, canopy_center_y + canopy_radius * 0.25))
		tree.add_child(canopy_back)

	var chop_center_offset: Vector2 = Vector2(0.0, -trunk_height * 0.6)
	tree.set_meta("chop_center_offset", chop_center_offset)
	tree.set_meta("chop_radius", canopy_radius)

	return tree

func _apply_big_tree_feather(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	if BigTreeFeatherShader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = BigTreeFeatherShader
	mat.set_shader_parameter("feather_px", big_tree_edge_feather_px)
	mat.set_shader_parameter("alpha_multiplier", big_tree_edge_alpha_multiplier)
	sprite.material = mat


func _damage_tree(column_x: int, tree_node: Node2D) -> void:
	if tree_node == null or not is_instance_valid(tree_node):
		return
	_flash_tree_hit(tree_node)
	var hits_variant: Variant = tree_node.get_meta("hits_remaining", 1)
	var hits_remaining: int = int(hits_variant) - 1
	tree_node.set_meta("hits_remaining", hits_remaining)
	if hits_remaining > 0:
		return
	_remove_tree(column_x, true)


func _flash_tree_hit(tree_node: Node2D) -> void:
	if tree_node == null or not is_instance_valid(tree_node):
		return
	var flash_tween_variant: Variant = tree_node.get_meta("hit_flash_tween", null)
	if flash_tween_variant is Tween:
		var previous_tween: Tween = flash_tween_variant as Tween
		if previous_tween != null and is_instance_valid(previous_tween):
			previous_tween.kill()
	tree_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tree_node.set_meta("hit_flash_tween", tween)
	tween.tween_property(tree_node, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.05)
	tween.tween_property(tree_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.09)


func _create_tree_canopy_polygon(radius: float, center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(10):
		var angle: float = TAU * (float(i) / 10.0)
		var radial_scale: float = 0.88 + 0.12 * sin(angle * 3.0)
		var p := center + Vector2(cos(angle), sin(angle)) * radius * radial_scale
		points.append(p)
	return points


func _column_random01(column_x: int, salt: int) -> float:
	var n: int = column_x * 374761393 + tree_seed * 668265263 + salt * 224682251
	n = n ^ (n >> 13)
	n = n * 1274126177
	n = n ^ (n >> 16)
	var positive: int = n & 0x7fffffff
	return float(positive) / 2147483647.0


func _remove_tree(column_x: int, spawn_wood_drops: bool = false) -> void:
	if not _active_trees.has(column_x):
		return
	_set_tree_protected_cell(Vector2i(column_x, _get_grass_cap_y()), false)
	_set_tree_protected_cell(Vector2i(column_x, _get_grass_cap_y() + 1), false)
	var tree: Node2D = _active_trees[column_x] as Node2D
	_active_trees.erase(column_x)
	if spawn_wood_drops and tree != null and is_instance_valid(tree):
		_spawn_wood_drops(tree.global_position)
	if tree != null and is_instance_valid(tree):
		tree.queue_free()

func _remove_grass_sprouts(column_x: int) -> void:
	if not _active_grass_sprouts.has(column_x):
		return
	var node: Node2D = _active_grass_sprouts[column_x] as Node2D
	_active_grass_sprouts.erase(column_x)
	if node != null and is_instance_valid(node):
		node.queue_free()

func _remove_painting_sprouts(column_x: int) -> void:
	if not _active_painting_sprouts.has(column_x):
		return
	var nodes_variant: Variant = _active_painting_sprouts[column_x]
	_active_painting_sprouts.erase(column_x)
	if nodes_variant is Array:
		var nodes: Array = nodes_variant
		for item: Variant in nodes:
			var node: Node2D = item as Node2D
			if node != null and is_instance_valid(node):
				node.queue_free()

func _update_painting_sprout_sway(delta: float) -> void:
	if _active_painting_sprouts.is_empty():
		return
	if delta <= 0.0:
		return
	var t: float = Time.get_ticks_msec() * 0.001 * painting_sprouts_swing_speed
	for value: Variant in _active_painting_sprouts.values():
		if not (value is Array):
			continue
		var nodes: Array = value
		for item: Variant in nodes:
			var node: Node2D = item as Node2D
			if node == null or not is_instance_valid(node):
				continue
			var min_deg_variant: Variant = node.get_meta("sway_min_deg", painting_sprouts_swing_min_degrees)
			var max_deg_variant: Variant = node.get_meta("sway_max_deg", painting_sprouts_swing_max_degrees)
			var min_deg: float = float(min_deg_variant)
			var max_deg: float = float(max_deg_variant)
			if max_deg < min_deg:
				var tmp: float = min_deg
				min_deg = max_deg
				max_deg = tmp
			var center_deg: float = (min_deg + max_deg) * 0.5
			var amp_deg: float = (max_deg - min_deg) * 0.5
			var phase_variant: Variant = node.get_meta("sway_phase", 0.0)
			var phase: float = float(phase_variant)
			var angle_deg: float = center_deg + sin(t + phase) * amp_deg
			node.rotation = deg_to_rad(angle_deg)


func _spawn_wood_drops(tree_global_position: Vector2) -> void:
	if WoodDropScene == null:
		return
	var horizontal_speeds: Array[float] = [-88.0, 0.0, 88.0]
	var bounce_speeds: Array[float] = [52.0, 44.0, 52.0]
	for i in range(horizontal_speeds.size()):
		var drop := WoodDropScene.instantiate()
		if drop == null:
			continue
		blocks_root.add_child(drop)
		if drop is Node2D:
			var drop_node: Node2D = drop as Node2D
			drop_node.global_position = tree_global_position + Vector2(0.0, -float(block_size) * 2.0)
			drop_node.set("spawn_horizontal_speed", horizontal_speeds[i])
			drop_node.set("bounce_up_speed", bounce_speeds[i])


func _set_tree_protected_cell(cell: Vector2i, enabled: bool) -> void:
	if enabled:
		_tree_protected_cells[cell] = true
	else:
		_tree_protected_cells.erase(cell)


func _is_tree_protected_cell(cell: Vector2i) -> bool:
	return _tree_protected_cells.has(cell)


func _create_custom_grass_texture() -> Texture2D:
	var size: int = maxi(block_size, 2)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)

	for y in range(size):
		var y_ratio: float = float(y) / float(maxi(size - 1, 1))
		for x in range(size):
			var c: Color
			if y_ratio <= 0.35:
				var t_top: float = y_ratio / 0.35
				c = grass_top_color.lerp(grass_mid_color, t_top)
			else:
				var t_dirt: float = (y_ratio - 0.35) / 0.65
				var dark_dirt: Color = dirt_color.darkened(0.08)
				c = grass_mid_color.lerp(dark_dirt, clampf(t_dirt, 0.0, 1.0))

			# Subtle repeating noise so tiles look alive but still connect cleanly.
			var pattern: int = (x * 13 + y * 7) % 11
			if pattern <= 1:
				c = c.lightened(0.06)
			elif pattern >= 9:
				c = c.darkened(0.05)

			img.set_pixel(x, y, c)

	# Grass blade highlights on upper area.
	var blade_height: int = maxi(int(round(float(size) * 0.25)), 2)
	for x in range(size):
		if (x % 3) == 1:
			for y in range(blade_height):
				var p: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, p.lightened(0.10))

	return ImageTexture.create_from_image(img)

func _create_top_line_texture() -> Texture2D:
	var h: int = clampi(floor_cycle_top_line_height_px, 1, block_size)
	var edge_alpha: float = clampf(floor_cycle_top_line_edge_alpha, 0.0, 1.0)
	var center_alpha: float = clampf(floor_cycle_top_line_color.a, 0.0, 1.0)
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var alpha: float = center_alpha
		if h >= 2:
			var y_ratio: float = float(y) / float(h - 1)
			var center_dist: float = absf(y_ratio - 0.5) / 0.5
			var edge_t: float = clampf(center_dist, 0.0, 1.0)
			alpha = lerpf(center_alpha, center_alpha * edge_alpha, edge_t)
		var c: Color = Color(floor_cycle_top_line_color.r, floor_cycle_top_line_color.g, floor_cycle_top_line_color.b, alpha)
		img.set_pixel(0, y, c)
	return ImageTexture.create_from_image(img)

func _load_floor_cycle_textures() -> Array[Texture2D]:
	if not floor_cycle_enabled:
		return []

	var textures: Array[Texture2D] = []
	var count: int = clampi(floor_cycle_count, 0, 9999)
	for i in range(1, count + 1):
		var path: String = floor_cycle_path_format % i
		# New images might exist on disk before Godot has generated .import metadata.
		if not FileAccess.file_exists(path):
			continue
		var res: Resource = load(path)
		if res == null:
			continue
		if res is Texture2D:
			textures.append(res as Texture2D)
	return textures

func _create_floor_cycle_sprite(cell: Vector2i) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.centered = true
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var idx: int = posmod(cell.x + floor_cycle_offset, _floor_cycle_textures.size())
	var tex: Texture2D = _floor_cycle_textures[idx]
	visual.texture = tex

	var tex_size: Vector2 = tex.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		var target_w: float = float(maxi(floor_cycle_tile_size_px.x, 1))
		var target_h: float = float(maxi(floor_cycle_tile_size_px.y, 1))
		# Crop away the top part instead of vertically squashing the whole image.
		var cut_top_px: int = maxi(block_size - maxi(floor_cycle_tile_size_px.y, 1), 0)
		var cut_ratio: float = float(cut_top_px) / float(maxi(block_size, 1))
		var crop_y: float = tex_size.y * clampf(cut_ratio, 0.0, 0.95)
		var crop_h: float = maxf(tex_size.y - crop_y, 1.0)
		visual.region_enabled = true
		visual.region_rect = Rect2(0.0, crop_y, tex_size.x, crop_h)
		visual.scale = Vector2(target_w / tex_size.x, target_h / crop_h)
		# Align the top edge of the visual to the top edge of the collision cell.
		var y_offset: float = -0.5 * (float(block_size) - target_h)
		visual.position = Vector2(0.0, y_offset) + floor_cycle_visual_offset_px

	return visual

func _create_floor_cycle_top_line_sprite() -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = _floor_top_line_texture
	sprite.z_index = 1

	var thickness: float = clampf(floor_cycle_top_line_thickness, 0.05, 1.0)
	sprite.scale = Vector2(float(block_size), thickness)
	sprite.position = Vector2(-float(block_size) * 0.5, -float(block_size) * 0.5) + floor_cycle_visual_offset_px
	return sprite


func _create_block_sprite(region: Rect2i) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.texture = GROUND_TEXTURE
	visual.centered = true
	visual.region_enabled = true
	visual.region_rect = Rect2(region)
	visual.modulate = block_tint
	var tile_width: float = maxf(float(region.size.x), 1.0)
	var tile_height: float = maxf(float(region.size.y), 1.0)
	visual.scale = Vector2(float(block_size) / tile_width, float(block_size) / tile_height)
	return visual


func _is_cell_supported_for_placed_block(cell: Vector2i) -> bool:
	var below_cell: Vector2i = cell + Vector2i(0, 1)
	if _active_blocks.has(below_cell):
		return true
	if _falling_target_cells.has(below_cell):
		return true

	var probe_shape := RectangleShape2D.new()
	probe_shape.size = Vector2(float(block_size) * 0.65, 1.5)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	var local_center: Vector2 = _block_center_world(cell)
	var probe_local_position: Vector2 = Vector2(local_center.x, local_center.y + float(block_size) * 0.5 + 0.75)
	query.transform = Transform2D(0.0, to_global(probe_local_position))
	query.collision_mask = ANY_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 8)
	return not hits.is_empty()


func _spawn_falling_ground_block(start_cell: Vector2i, settled_cell: Vector2i) -> void:
	var falling_node := Node2D.new()
	falling_node.name = "FallingBlock_%d_%d" % [settled_cell.x, settled_cell.y]
	falling_node.position = _block_center_world(start_cell)
	falling_node.add_child(_create_block_sprite(ground_tile_region))
	blocks_root.add_child(falling_node)

	_falling_target_cells[settled_cell] = true
	var entry: Dictionary = {
		"node": falling_node,
		"target_cell": settled_cell,
		"max_fall_y": _block_center_world(settled_cell).y,
		"velocity_y": 0.0,
	}
	_falling_blocks.append(entry)


func _update_falling_blocks(delta: float) -> void:
	if _falling_blocks.is_empty():
		return

	for i in range(_falling_blocks.size() - 1, -1, -1):
		var entry: Dictionary = _falling_blocks[i]
		var node_variant: Variant = entry.get("node", null)
		if not (node_variant is Node2D):
			_release_falling_target_from_entry(entry)
			_falling_blocks.remove_at(i)
			continue

		var falling_node: Node2D = node_variant as Node2D
		if falling_node == null or not is_instance_valid(falling_node):
			_release_falling_target_from_entry(entry)
			_falling_blocks.remove_at(i)
			continue

		var max_fall_y: float = float(entry.get("max_fall_y", falling_node.position.y))
		var velocity_y: float = float(entry.get("velocity_y", 0.0))
		if _is_falling_block_touching_any_collision(falling_node.position):
			var touching_cell: Vector2i = _world_to_block(falling_node.position)
			_finalize_falling_ground_block(entry, falling_node, touching_cell)
			_falling_blocks.remove_at(i)
			continue
		velocity_y = minf(velocity_y + placed_block_fall_gravity * delta, placed_block_fall_max_speed)
		var requested_fall_delta_y: float = minf(velocity_y * delta, max_fall_y - falling_node.position.y)
		var safe_fraction: float = _compute_fall_safe_fraction(falling_node.position, requested_fall_delta_y)
		var moved_delta_y: float = requested_fall_delta_y * safe_fraction
		var next_y: float = falling_node.position.y + moved_delta_y
		falling_node.position.y = next_y
		if safe_fraction < 1.0:
			var final_cell: Vector2i = _world_to_block(falling_node.position)
			_finalize_falling_ground_block(entry, falling_node, final_cell)
			_falling_blocks.remove_at(i)
			continue
		if next_y >= max_fall_y:
			var fallback_cell_variant: Variant = entry.get("target_cell", null)
			var fallback_cell: Vector2i = _world_to_block(falling_node.position)
			if fallback_cell_variant is Vector2i:
				fallback_cell = fallback_cell_variant as Vector2i
			_finalize_falling_ground_block(entry, falling_node, fallback_cell)
			_falling_blocks.remove_at(i)
			continue

		entry["velocity_y"] = velocity_y
		_falling_blocks[i] = entry


func _finalize_falling_ground_block(entry: Dictionary, falling_node: Node2D, target_cell: Vector2i) -> void:
	_release_falling_target_from_entry(entry)
	if not _active_blocks.has(target_cell) and not _is_tree_protected_cell(target_cell):
		_dug_blocks.erase(target_cell)
		_create_ground_block(target_cell)
	falling_node.queue_free()


func _compute_fall_safe_fraction(center_local: Vector2, delta_y: float) -> float:
	if delta_y <= 0.0:
		return 1.0
	var probe_shape := RectangleShape2D.new()
	probe_shape.size = Vector2(float(block_size) * 0.9, float(block_size) * 0.9)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe_shape
	query.transform = Transform2D(0.0, to_global(center_local))
	query.motion = Vector2(0.0, delta_y)
	query.collision_mask = ANY_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var cast_result: PackedFloat32Array = get_world_2d().direct_space_state.cast_motion(query)
	if cast_result.size() == 0:
		return 1.0
	return clampf(cast_result[0], 0.0, 1.0)


func _is_falling_block_touching_any_collision(center_local: Vector2) -> bool:
	if _is_falling_block_touching_placed_block(center_local):
		return true

	var contact_shape := RectangleShape2D.new()
	var tolerance: float = maxf(placed_block_contact_tolerance_px, 0.0)
	var shape_size: float = float(block_size) + tolerance * 2.0
	contact_shape.size = Vector2(shape_size, shape_size)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = contact_shape
	query.transform = Transform2D(0.0, to_global(center_local))
	query.collision_mask = ANY_COLLISION_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 16)
	return not hits.is_empty()


func _is_falling_block_touching_placed_block(center_local: Vector2) -> bool:
	var tolerance: float = maxf(placed_block_contact_tolerance_px, 0.0)
	var max_axis_delta: float = float(block_size) + tolerance
	var center_cell: Vector2i = _world_to_block(center_local)

	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			var neighbor_cell: Vector2i = center_cell + Vector2i(x_offset, y_offset)
			if not _active_blocks.has(neighbor_cell):
				continue

			var neighbor_center: Vector2 = _block_center_world(neighbor_cell)
			var delta: Vector2 = center_local - neighbor_center
			if absf(delta.x) <= max_axis_delta and absf(delta.y) <= max_axis_delta:
				return true

	return false


func _release_falling_target_from_entry(entry: Dictionary) -> void:
	var target_cell_variant: Variant = entry.get("target_cell", null)
	if target_cell_variant is Vector2i:
		_falling_target_cells.erase(target_cell_variant as Vector2i)


func _remove_block(cell: Vector2i, mark_as_dug: bool) -> void:
	if mark_as_dug:
		_dug_blocks[cell] = true
		_spawn_block_drop(cell)
		var grass_cap_y: int = _get_grass_cap_y()
		var grass_support_y: int = grass_cap_y + 1
		if cell.y == grass_cap_y:
			_remove_tree(cell.x)
			_remove_grass_sprouts(cell.x)
			_remove_painting_sprouts(cell.x)
		elif cell.y == grass_support_y:
			# If the support block directly under the grass cap is removed,
			# clear decorative sprouts in that column.
			_remove_grass_sprouts(cell.x)
			_remove_painting_sprouts(cell.x)

	if not _active_blocks.has(cell):
		return
	var body: Node = _active_blocks[cell] as Node
	_active_blocks.erase(cell)
	if body != null and is_instance_valid(body):
		body.queue_free()


func _spawn_block_drop(cell: Vector2i) -> void:
	if GroundBlockDropScene == null:
		return
	var drop := GroundBlockDropScene.instantiate()
	if drop == null:
		return
	var spawn_position: Vector2 = _block_center_world(cell)
	blocks_root.add_child(drop)
	if drop is Node2D:
		var drop_node := drop as Node2D
		drop_node.position = spawn_position
		if drop_node.has_method("set"):
			drop_node.set("spawn_horizontal_speed", 0.0)


func _trim_outside_range(keep_min_x: int, keep_max_x: int) -> void:
	if generated_max_x < generated_min_x:
		return

	if keep_min_x <= generated_min_x and keep_max_x >= generated_max_x:
		return

	if keep_min_x > generated_min_x:
		for x in range(generated_min_x, keep_min_x):
			_remove_tree(x)
			_remove_grass_sprouts(x)
			_remove_painting_sprouts(x)
			for y in range(_get_grass_cap_y(), generated_max_y + 1):
				_remove_block(Vector2i(x, y), false)
		generated_min_x = keep_min_x

	if keep_max_x < generated_max_x:
		for x in range(keep_max_x + 1, generated_max_x + 1):
			_remove_tree(x)
			_remove_grass_sprouts(x)
			_remove_painting_sprouts(x)
			for y in range(_get_grass_cap_y(), generated_max_y + 1):
				_remove_block(Vector2i(x, y), false)
		generated_max_x = keep_max_x


func _world_to_block(local_position: Vector2) -> Vector2i:
	var bx: int = int(floor(local_position.x / float(block_size)))
	var by: int = int(floor(local_position.y / float(block_size)))
	return Vector2i(bx, by)


func _block_center_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * float(block_size),
		(float(cell.y) + 0.5) * float(block_size)
	)


func _circle_overlaps_block(local_center: Vector2, radius: float, cell: Vector2i) -> bool:
	var min_x: float = float(cell.x * block_size)
	var min_y: float = float(cell.y * block_size)
	var max_x: float = min_x + float(block_size)
	var max_y: float = min_y + float(block_size)

	var closest_x: float = clampf(local_center.x, min_x, max_x)
	var closest_y: float = clampf(local_center.y, min_y, max_y)
	var delta: Vector2 = local_center - Vector2(closest_x, closest_y)
	return delta.length_squared() <= radius * radius
