extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var zombie_scene: PackedScene = load("res://game/enemies/zombie.tscn")
	if zombie_scene == null:
		errors.append("Failed to load Zombie.tscn")
		_report(errors)
		return
	
	var zombie_node: Node = zombie_scene.instantiate()
	get_root().add_child(zombie_node)
	await process_frame

	var zombie_script: Script = zombie_node.get_script()
	if zombie_script == null or zombie_script.resource_path != "res://game/enemies/zombie.gd":
		errors.append("Zombie root missing expected script res://game/enemies/zombie.gd")
	else:
		var max_health_v = zombie_node.get("max_health")
		if typeof(max_health_v) != TYPE_INT:
			errors.append("Zombie max_health must be int")
		elif int(max_health_v) != 5:
			errors.append("Zombie max_health expected 5, got %s" % str(max_health_v))

		var health_v = zombie_node.get("health")
		if typeof(health_v) != TYPE_INT:
			errors.append("Zombie health must be int")
		elif int(health_v) != 5:
			errors.append("Zombie health expected 5, got %s" % str(health_v))
	
	_cleanup(zombie_node)
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
