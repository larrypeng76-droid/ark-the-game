extends SceneTree

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
	if player == null:
		errors.append("Player root is not Player")
		_cleanup(player_node)
		_report(errors)
		return
	
	player.state_machine.change_state("LandState")
	player.state_machine.physics_update(0.016)
	if player.state_machine.current_state == null or player.state_machine.current_state.name != "FallState":
		errors.append("LandState should fall when not on floor")
	
	player.state_machine.change_state("HardLandState")
	player.state_machine.physics_update(0.016)
	if player.state_machine.current_state == null or player.state_machine.current_state.name != "FallState":
		errors.append("HardLandState should fall when not on floor")
	
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
