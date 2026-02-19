extends SceneTree

const PLAYER_SCRIPT_PATH := "res://game/player/player.gd"
const MANAGER_SCRIPT_PATH := "res://game/features/turret/turret_manager.gd"
const RULES_SCRIPT_PATH := "res://game/features/turret/turret_rules.gd"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []

	var manager_script: GDScript = load(MANAGER_SCRIPT_PATH) as GDScript
	if manager_script == null:
		errors.append("Missing turret manager script: %s" % MANAGER_SCRIPT_PATH)
		_report(errors)
		return
	var manager: Node = manager_script.new() as Node
	if manager == null:
		errors.append("Failed to instantiate turret manager")
	else:
		if not manager.has_method("can_place_turret_at_world"):
			errors.append("TurretManager must expose can_place_turret_at_world()")
		if not manager.has_method("place_turret_at_world"):
			errors.append("TurretManager must expose place_turret_at_world()")
		manager.free()

	var rules_script: GDScript = load(RULES_SCRIPT_PATH) as GDScript
	if rules_script == null:
		errors.append("Missing turret rules script: %s" % RULES_SCRIPT_PATH)
	else:
		var rules: RefCounted = rules_script.new() as RefCounted
		if rules == null or not rules.has_method("can_place_turret"):
			errors.append("TurretRules must expose can_place_turret(cell, ...)")

	var player_source: String = FileAccess.get_file_as_string(PLAYER_SCRIPT_PATH)
	if player_source.find("TempTurretScene.instantiate(") != -1:
		errors.append("Player must not instantiate turret visuals directly; use TurretManager.place_turret_at_world().")
	if player_source.find("_turret_manager.call(\"place_turret_at_world\"") == -1:
		errors.append("Player turret placement must route through TurretManager.place_turret_at_world().")

	_report(errors)


func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for err in errors:
			push_error(err)
		quit(1)
		return
	quit(0)
