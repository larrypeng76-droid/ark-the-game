extends SceneTree

const RULES_SCRIPT_PATH := "res://game/features/turret/turret_rules.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var rules_script: GDScript = load(RULES_SCRIPT_PATH) as GDScript
	if rules_script == null:
		errors.append("Failed to load %s" % RULES_SCRIPT_PATH)
		_report(errors)
		return
	var rules: RefCounted = rules_script.new() as RefCounted
	if rules == null:
		errors.append("Failed to instantiate TurretRules")
		_report(errors)
		return

	var cell := Vector2i(2, 3)
	var target := Vector2(20.0, 30.0)
	var base_context := {
		"placement_bounds": Rect2(Vector2.ZERO, Vector2(100.0, 100.0)),
		"occupied_cells": {},
		"player_overlap_check": Callable(self, "_always_false"),
		"vehicle_overlap_check": Callable(self, "_always_false"),
	}

	var ok_result: Dictionary = rules.call("can_place_turret", cell, target, base_context)
	if not bool(ok_result.get("ok", false)):
		errors.append("Expected in-bounds clear placement to pass")

	var out_of_bounds_context := base_context.duplicate(true)
	out_of_bounds_context["placement_bounds"] = Rect2(Vector2.ZERO, Vector2(10.0, 10.0))
	var out_of_bounds_result: Dictionary = rules.call("can_place_turret", cell, target, out_of_bounds_context)
	if bool(out_of_bounds_result.get("ok", true)):
		errors.append("Expected out_of_bounds placement to fail")

	var occupied_context := base_context.duplicate(true)
	var occupied_cells := {}
	occupied_cells[cell] = true
	occupied_context["occupied_cells"] = occupied_cells
	var occupied_result: Dictionary = rules.call("can_place_turret", cell, target, occupied_context)
	if bool(occupied_result.get("ok", true)):
		errors.append("Expected occupied-cell placement to fail")

	var player_overlap_context := base_context.duplicate(true)
	player_overlap_context["player_overlap_check"] = Callable(self, "_always_true")
	var player_overlap_result: Dictionary = rules.call("can_place_turret", cell, target, player_overlap_context)
	if bool(player_overlap_result.get("ok", true)):
		errors.append("Expected player-overlap placement to fail")

	var vehicle_overlap_context := base_context.duplicate(true)
	vehicle_overlap_context["vehicle_overlap_check"] = Callable(self, "_always_true")
	var vehicle_overlap_result: Dictionary = rules.call("can_place_turret", cell, target, vehicle_overlap_context)
	if bool(vehicle_overlap_result.get("ok", true)):
		errors.append("Expected vehicle-overlap placement to fail")

	_report(errors)


func _always_false(_target: Vector2) -> bool:
	return false


func _always_true(_target: Vector2) -> bool:
	return true


func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for err in errors:
			push_error(err)
		quit(1)
		return
	quit(0)
