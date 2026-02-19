extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var shooter_scene: PackedScene = load("res://game/enemies/shooter.tscn")
	if shooter_scene == null:
		errors.append("Failed to load Shooter.tscn")
		_report(errors)
		return
	
	var shooter: Node = shooter_scene.instantiate()
	get_root().add_child(shooter)
	await process_frame
	
	var anim: AnimatedSprite2D = shooter.get_node_or_null("Visual/AnimatedSprite2D")
	if anim == null:
		errors.append("Missing Visual/AnimatedSprite2D")
		_cleanup(shooter)
		_report(errors)
		return
	
	var contact: Area2D = shooter.get_node_or_null("ContactDamage")
	if contact == null:
		errors.append("Missing ContactDamage Area2D")
		_cleanup(shooter)
		_report(errors)
		return

	var shooter_script: Script = shooter.get_script()
	if shooter_script == null or shooter_script.resource_path != "res://game/enemies/shooter.gd":
		errors.append("Shooter root missing expected script res://game/enemies/shooter.gd")
	else:
		var max_health_v = shooter.get("max_health")
		if typeof(max_health_v) != TYPE_INT:
			errors.append("Shooter max_health must be int")
		elif int(max_health_v) != 15:
			errors.append("Shooter max_health expected 15, got %s" % str(max_health_v))

		var health_v = shooter.get("health")
		if typeof(health_v) != TYPE_INT:
			errors.append("Shooter health must be int")
		elif int(health_v) != 15:
			errors.append("Shooter health expected 15, got %s" % str(health_v))
	
	var frames := anim.sprite_frames
	if frames == null:
		errors.append("AnimatedSprite2D has no SpriteFrames")
		_cleanup(shooter)
		_report(errors)
		return
	
	for name in ["idle", "run", "attack"]:
		if not frames.has_animation(name):
			errors.append("Missing animation: %s" % name)
			continue
		if frames.get_frame_count(name) == 0:
			errors.append("Animation has 0 frames: %s" % name)
	
	_cleanup(shooter)
	_report(errors)

func _cleanup(shooter: Node) -> void:
	if shooter and is_instance_valid(shooter):
		shooter.queue_free()

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
