extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var bullet_scene: PackedScene = load("res://Game/Player/player_bullet.tscn")
	if bullet_scene == null:
		errors.append("Failed to load player_bullet.tscn")
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
	
	if not bullet.has_method("setup"):
		errors.append("PlayerBullet missing setup(direction, speed)")
	
	if bullet.collision_layer != 8:
		errors.append("PlayerBullet collision_layer expected 8, got %s" % str(bullet.collision_layer))
	
	if (bullet.collision_mask & 2) == 0:
		errors.append("PlayerBullet collision_mask must include Enemy layer")
	
	var shape: CollisionShape2D = bullet.get_node_or_null("CollisionShape2D")
	if shape == null:
		errors.append("PlayerBullet missing CollisionShape2D")
	
	_cleanup(bullet_node)
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
