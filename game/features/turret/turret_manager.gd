extends Node

const TempTurretScene := preload("res://game/features/items/temp_turret/temp_turret.tscn")
const TurretRulesScript := preload("res://game/features/turret/turret_rules.gd")
const MANAGER_GROUP_NAME := "turret_manager"

var _rules: RefCounted
var _ground_node: Node2D
var _placement_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
var _player_overlap_check: Callable
var _vehicle_overlap_check: Callable
var _placement_mode: String = "cursor"

var _records_by_cell: Dictionary = {}
var _records_by_id: Dictionary = {}
var _next_record_id: int = 1


func _ready() -> void:
	add_to_group(MANAGER_GROUP_NAME)
	_rules = TurretRulesScript.new()


func configure_context(
	ground_node: Node2D,
	placement_bounds: Rect2,
	player_overlap_check: Callable,
	vehicle_overlap_check: Callable,
	placement_mode: String = "cursor"
) -> void:
	_ground_node = ground_node
	_placement_bounds = placement_bounds
	_player_overlap_check = player_overlap_check
	_vehicle_overlap_check = vehicle_overlap_check
	_placement_mode = placement_mode


func can_place_turret_at_world(target_world_position: Vector2) -> Dictionary:
	if _rules == null:
		_rules = TurretRulesScript.new()
	if _ground_node == null or not is_instance_valid(_ground_node):
		return {"ok": false, "reason": "ground_missing"}
	if _rules == null:
		return {"ok": false, "reason": "rules_missing"}

	var cell: Vector2i = _world_to_cell(target_world_position)
	var cell_center_world: Vector2 = _cell_center_world(cell)
	var placement_world_position: Vector2 = target_world_position
	if _placement_mode == "grid":
		placement_world_position = cell_center_world
	var context := {
		"placement_bounds": _placement_bounds,
		"occupied_cells": _records_by_cell,
		"player_overlap_check": _player_overlap_check,
		"vehicle_overlap_check": _vehicle_overlap_check,
	}
	var decision: Dictionary = _rules.call("can_place_turret", cell, placement_world_position, context)
	decision["cell"] = cell
	decision["cell_center_world"] = cell_center_world
	decision["placement_world_position"] = placement_world_position
	return decision


func place_turret_at_world(target_world_position: Vector2) -> Dictionary:
	var decision: Dictionary = can_place_turret_at_world(target_world_position)
	if not bool(decision.get("ok", false)):
		return decision

	if TempTurretScene == null:
		return {"ok": false, "reason": "scene_missing"}
	var turret_node := TempTurretScene.instantiate() as Node2D
	if turret_node == null:
		return {"ok": false, "reason": "instantiate_failed"}

	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	if scene_root == null:
		turret_node.queue_free()
		return {"ok": false, "reason": "scene_root_missing"}
	scene_root.add_child(turret_node)

	var cell: Vector2i = decision["cell"] as Vector2i
	var cell_center_world: Vector2 = decision["cell_center_world"] as Vector2
	var placement_world_position: Vector2 = decision["placement_world_position"] as Vector2
	var block_size_px: float = _get_ground_block_size_px()
	if _placement_mode == "grid" and turret_node.has_method("set_cell_world_position"):
		turret_node.call("set_cell_world_position", cell_center_world, block_size_px)
	elif _placement_mode == "cursor" and turret_node.has_method("set_click_world_position"):
		turret_node.call("set_click_world_position", placement_world_position)
	else:
		turret_node.global_position = placement_world_position

	var record_id: int = _next_record_id
	_next_record_id += 1
	var record := {
		"id": record_id,
		"cell": cell,
		"cell_center_world": cell_center_world,
		"rotation": 0.0,
		"level": 1,
		"state": "active",
	}
	_records_by_cell[cell] = record
	_records_by_id[record_id] = record
	turret_node.set_meta("record_id", record_id)
	turret_node.set_meta("grid_cell_center_world", cell_center_world)
	if turret_node.has_method("apply_visual_record"):
		turret_node.call("apply_visual_record", record)
	return {"ok": true, "reason": "ok", "record_id": record_id}


func get_turret_record(record_id: int) -> Variant:
	if not _records_by_id.has(record_id):
		return null
	return _records_by_id[record_id]


func get_turret_count() -> int:
	return _records_by_id.size()


func _get_ground_block_size_px() -> float:
	var block_size_variant: Variant = _ground_node.get("block_size")
	var block_size_px: float = 10.0
	if block_size_variant is int:
		block_size_px = float(block_size_variant as int)
	elif block_size_variant is float:
		block_size_px = block_size_variant as float
	return maxf(block_size_px, 1.0)


func _world_to_cell(target_world_position: Vector2) -> Vector2i:
	var block_size_px: float = _get_ground_block_size_px()
	var local_position: Vector2 = _ground_node.to_local(target_world_position)
	return Vector2i(
		int(floor(local_position.x / block_size_px)),
		int(floor(local_position.y / block_size_px))
	)


func _cell_center_world(cell: Vector2i) -> Vector2:
	var block_size_px: float = _get_ground_block_size_px()
	var cell_center_local := Vector2(
		(float(cell.x) + 0.5) * block_size_px,
		(float(cell.y) + 0.5) * block_size_px
	)
	return _ground_node.to_global(cell_center_local)
