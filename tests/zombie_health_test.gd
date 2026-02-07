extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var zombie_scene: PackedScene = load("res://Game/Enemies/Zombie.tscn")
	if zombie_scene == null:
		errors.append("Failed to load Zombie.tscn")
		_report(errors)
		return
	
	var zombie_node: Node = zombie_scene.instantiate()
	get_root().add_child(zombie_node)
	await process_frame
	
	var zombie: Zombie = zombie_node as Zombie
	if zombie == null:
		errors.append("Zombie root is not Zombie")
	else:
		if zombie.max_health != 5:
			errors.append("Zombie max_health expected 5, got %s" % str(zombie.max_health))
		if zombie.health != 5:
			errors.append("Zombie health expected 5, got %s" % str(zombie.health))
	
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
