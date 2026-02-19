extends SceneTree

const TURRET_SCRIPT_PATH := "res://game/features/items/temp_turret/temp_turret.gd"
const PLAYER_BULLET_SCENE_PATH := "res://game/player/player_bullet.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []

	var source: String = FileAccess.get_file_as_string(TURRET_SCRIPT_PATH)
	if source.is_empty():
		errors.append("Failed to read %s" % TURRET_SCRIPT_PATH)
		_report(errors)
		return
	var required_tokens: Array[String] = [
		"const PlayerBulletScene := preload(\"res://game/player/player_bullet.tscn\")",
		"func _find_nearest_enemy()",
		"get_nodes_in_group(\"enemy\")",
		"func _try_fire_at_target(",
	]
	for token: String in required_tokens:
		if source.find(token) == -1:
			errors.append("TempTurret combat capability missing token: %s" % token)

	var bullet_scene: PackedScene = load(PLAYER_BULLET_SCENE_PATH)
	if bullet_scene == null:
		errors.append("Failed to load %s" % PLAYER_BULLET_SCENE_PATH)
		_report(errors)
		return

	var bullet_node: Node = bullet_scene.instantiate()
	get_root().add_child(bullet_node)
	await process_frame

	var bullet: Area2D = bullet_node as Area2D
	if bullet == null:
		errors.append("PlayerBullet root is not Area2D")
		_cleanup(bullet_node)
		_report(errors)
		return
	if not bullet.has_method("setup_direction"):
		errors.append("PlayerBullet missing setup_direction(direction, speed)")
	if bullet.collision_layer != 8:
		errors.append("PlayerBullet collision_layer expected 8, got %s" % str(bullet.collision_layer))
	if (bullet.collision_mask & 2) == 0:
		errors.append("PlayerBullet collision_mask must include Enemy layer")

	_cleanup(bullet_node)
	_report(errors)


func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for err in errors:
			push_error(err)
		quit(1)
		return
	quit(0)
