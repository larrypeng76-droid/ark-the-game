extends SceneTree

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
		_cleanup(player_node)
		_report(errors)
		return

	var state_machine: Node = player_node.get("state_machine") as Node
	if state_machine == null:
		errors.append("Player missing state_machine")
		_cleanup(player_node)
		_report(errors)
		return

	state_machine.call("change_state", "LandState")
	state_machine.call("physics_update", 0.016)
	var current_state: Node = state_machine.get("current_state") as Node
	if current_state == null or current_state.name != "FallState":
		errors.append("LandState should fall when not on floor")

	state_machine.call("change_state", "HardLandState")
	state_machine.call("physics_update", 0.016)
	current_state = state_machine.get("current_state") as Node
	if current_state == null or current_state.name != "FallState":
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
