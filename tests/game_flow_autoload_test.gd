extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	var game_flow: Node = get_root().get_node_or_null("GameFlow")
	if game_flow == null:
		errors.append("Missing autoload node: /root/GameFlow")
		_report(errors)
		return

	for method_name in ["set_paused", "restart_game", "go_to_main_menu"]:
		if not game_flow.has_method(method_name):
			errors.append("GameFlow missing method: %s" % method_name)

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
