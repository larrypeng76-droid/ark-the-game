extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var scene: PackedScene = load("res://game/enemies/enemy_bullet.tscn")
	if scene == null:
		errors.append("Failed to load enemy_bullet.tscn")
		_report(errors)
		return

	var node: Node = scene.instantiate()
	get_root().add_child(node)
	await process_frame

	var damage_area: Area2D = node.get_node_or_null("DamageArea")
	if damage_area == null:
		errors.append("Missing DamageArea")
	else:
		if damage_area.collision_layer != 16:
			errors.append("DamageArea collision_layer expected 16 (EnemyAttack)")
		if (damage_area.collision_mask & 1) == 0:
			errors.append("DamageArea collision_mask must include 1 (Player)")

	var terrain_sensor: Area2D = node.get_node_or_null("TerrainSensor")
	if terrain_sensor == null:
		errors.append("Missing TerrainSensor")
	else:
		if (terrain_sensor.collision_mask & 4) == 0:
			errors.append("TerrainSensor collision_mask must include 4 (Terrain)")

	_cleanup(node)
	_report(errors)

func _cleanup(node: Node) -> void:
	if node and is_instance_valid(node):
		node.queue_free()

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)

