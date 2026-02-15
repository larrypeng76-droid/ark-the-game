extends SceneTree

const EXPECTED_HEARTS := "♥♥♥♥♥♥♥♥♥♥"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var player_scene: PackedScene = load("res://game/player/player.tscn")
	if player_scene == null:
		errors.append("Failed to load Player.tscn")
		_report(errors)
		return
	
	var player_node: Node = player_scene.instantiate()
	get_root().add_child(player_node)
	await process_frame

	var player_script: Script = player_node.get_script()
	if player_script == null or player_script.resource_path != "res://game/player/player.gd":
		errors.append("Player root missing expected script res://game/player/player.gd")
	else:
		var max_health_v = player_node.get("max_health")
		if typeof(max_health_v) != TYPE_INT:
			errors.append("Player max_health must be int")
		elif int(max_health_v) != 10:
			errors.append("Player max_health expected 10, got %s" % str(max_health_v))

		var health_v = player_node.get("health")
		if typeof(health_v) != TYPE_INT:
			errors.append("Player health must be int")
		elif int(health_v) != 10:
			errors.append("Player health expected 10, got %s" % str(health_v))
	
	var hearts: Label = player_node.get_node_or_null("HUD/MarginContainer/Hearts")
	if hearts == null:
		errors.append("Missing HUD/MarginContainer/Hearts")
	else:
		if hearts.text != EXPECTED_HEARTS:
			errors.append("Hearts text mismatch: %s" % hearts.text)
	
	var hitbox: Area2D = player_node.get_node_or_null("Visual/HitBoxes/HitBoxJab")
	if hitbox == null:
		errors.append("Missing Visual/HitBoxes/HitBoxJab")
	else:
		var damage_v = hitbox.get("damage")
		if typeof(damage_v) != TYPE_INT:
			errors.append("HitBoxJab damage must be int")
		elif int(damage_v) != 2:
			errors.append("HitBoxJab damage expected 2, got %s" % str(damage_v))
	
	player_node.queue_free()
	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
