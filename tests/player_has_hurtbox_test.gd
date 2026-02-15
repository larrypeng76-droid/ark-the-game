extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var player_scene: PackedScene = load("res://game/player/player.tscn")
	if player_scene == null:
		errors.append("Failed to load player.tscn")
		_report(errors)
		return

	var player_node: Node = player_scene.instantiate()
	get_root().add_child(player_node)
	await process_frame

	var hurtbox: Area2D = player_node.get_node_or_null("HurtBox")
	if hurtbox == null:
		errors.append("Missing HurtBox Area2D on Player")
		_cleanup(player_node)
		_report(errors)
		return

	var script: Script = hurtbox.get_script()
	if script == null or script.resource_path != "res://core/combat/hurtbox.gd":
		errors.append("HurtBox must use res://core/combat/hurtbox.gd")

	if hurtbox.collision_layer != 1:
		errors.append("HurtBox collision_layer expected 1 (Player), got %s" % str(hurtbox.collision_layer))
	if (hurtbox.collision_mask & 16) == 0:
		errors.append("HurtBox collision_mask must include 16 (EnemyAttack)")

	var shape_standing: CollisionShape2D = hurtbox.get_node_or_null("CollisionShapeStanding")
	var shape_crouched: CollisionShape2D = hurtbox.get_node_or_null("CollisionShapeCrouched")
	if shape_standing == null:
		errors.append("Missing HurtBox/CollisionShapeStanding")
	if shape_crouched == null:
		errors.append("Missing HurtBox/CollisionShapeCrouched")

	_cleanup(player_node)
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

