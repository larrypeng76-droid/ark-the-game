extends SceneTree

const TURRET_VISUAL_SCRIPT_PATH := "res://game/features/items/temp_turret/temp_turret.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []
	var source: String = FileAccess.get_file_as_string(TURRET_VISUAL_SCRIPT_PATH)
	if source.is_empty():
		errors.append("Failed to read %s" % TURRET_VISUAL_SCRIPT_PATH)
		_report(errors)
		return

	var forbidden_authority_tokens: Array[String] = [
		"_records_by_cell",
		"_records_by_id",
		"can_place_turret",
		"place_turret_at_world",
	]
	for token: String in forbidden_authority_tokens:
		if source.find(token) != -1:
			errors.append("TempTurret visual script must not own authority logic/token: %s" % token)

	if source.find("func apply_visual_record(") == -1:
		errors.append("TempTurret visual script should expose apply_visual_record(record) for view updates")

	_report(errors)


func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for err in errors:
			push_error(err)
		quit(1)
		return
	quit(0)
