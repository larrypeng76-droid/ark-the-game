extends SceneTree

const EXPECTED_HEARTS := "♥♥♥♥♥♥♥♥♥♥"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var player_scene: PackedScene = load("res://Game/Player/Player.tscn")
	if player_scene == null:
		errors.append("Failed to load Player.tscn")
		_report(errors)
		return
	
	var player_node: Node = player_scene.instantiate()
	get_root().add_child(player_node)
	await process_frame
	
	var player: Player = player_node as Player
	if player.max_health != 10:
		errors.append("Player max_health expected 10, got %s" % str(player.max_health))
	if player.health != 10:
		errors.append("Player health expected 10, got %s" % str(player.health))
	
	var hearts: Label = player.get_node_or_null("HUD/MarginContainer/Hearts")
	if hearts == null:
		errors.append("Missing HUD/MarginContainer/Hearts")
	else:
		if hearts.text != EXPECTED_HEARTS:
			errors.append("Hearts text mismatch: %s" % hearts.text)
	
	var hitbox: Hitbox = player.get_node_or_null("Visual/HitBoxes/HitBoxJab")
	if hitbox == null:
		errors.append("Missing Visual/HitBoxes/HitBoxJab")
	else:
		if hitbox.damage != 2:
			errors.append("HitBoxJab damage expected 2, got %s" % str(hitbox.damage))
	
	player_node.queue_free()
	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
