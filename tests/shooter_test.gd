extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var shooter_scene: PackedScene = load("res://Game/Enemies/Shooter.tscn")
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
	
	var shooter_body: Shooter = shooter as Shooter
	if shooter_body == null:
		errors.append("Shooter root is not Shooter")
	else:
		if shooter_body.max_health != 5:
			errors.append("Shooter max_health expected 5, got %s" % str(shooter_body.max_health))
		if shooter_body.health != 5:
			errors.append("Shooter health expected 5, got %s" % str(shooter_body.health))
	
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
