extends RefCounted

const REASON_OK := "ok"
const REASON_OUT_OF_BOUNDS := "out_of_bounds"
const REASON_OCCUPIED := "occupied"
const REASON_PLAYER_OVERLAP := "player_overlap"
const REASON_VEHICLE_OVERLAP := "vehicle_overlap"


func can_place_turret(cell: Vector2i, target_world_position: Vector2, context: Dictionary) -> Dictionary:
	var bounds_variant: Variant = context.get("placement_bounds", null)
	if bounds_variant is Rect2:
		var bounds: Rect2 = bounds_variant as Rect2
		if not bounds.has_point(target_world_position):
			return {"ok": false, "reason": REASON_OUT_OF_BOUNDS}

	var occupied_variant: Variant = context.get("occupied_cells", null)
	if occupied_variant is Dictionary:
		var occupied_cells: Dictionary = occupied_variant as Dictionary
		if occupied_cells.has(cell):
			return {"ok": false, "reason": REASON_OCCUPIED}

	var player_overlap_callable_variant: Variant = context.get("player_overlap_check", null)
	if player_overlap_callable_variant is Callable:
		var player_overlap_callable: Callable = player_overlap_callable_variant as Callable
		if player_overlap_callable.is_valid():
			var player_overlap_result: Variant = player_overlap_callable.call(target_world_position)
			if player_overlap_result is bool and (player_overlap_result as bool):
				return {"ok": false, "reason": REASON_PLAYER_OVERLAP}

	var vehicle_overlap_callable_variant: Variant = context.get("vehicle_overlap_check", null)
	if vehicle_overlap_callable_variant is Callable:
		var vehicle_overlap_callable: Callable = vehicle_overlap_callable_variant as Callable
		if vehicle_overlap_callable.is_valid():
			var vehicle_overlap_result: Variant = vehicle_overlap_callable.call(target_world_position)
			if vehicle_overlap_result is bool and (vehicle_overlap_result as bool):
				return {"ok": false, "reason": REASON_VEHICLE_OVERLAP}

	return {"ok": true, "reason": REASON_OK}
