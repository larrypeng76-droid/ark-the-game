extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var missing: Array[String] = []

	for action_name in ["attackShoot"]:
		if not InputMap.has_action(action_name):
			missing.append(action_name)

	if missing.size() > 0:
		errors.append("Missing input action(s) in project.godot: %s" % ", ".join(missing))
		_report(errors)
		return

	# Make sure the action has key events bound.
	var events := InputMap.action_get_events("attackShoot")
	if events.is_empty():
		errors.append("attackShoot has no events bound")
		_report(errors)
		return

	var has_enter: bool = false
	var has_kp_enter: bool = false
	for e in events:
		if e is InputEventKey:
			var key_event: InputEventKey = e
			if key_event.physical_keycode == KEY_ENTER:
				has_enter = true
			if key_event.physical_keycode == KEY_KP_ENTER:
				has_kp_enter = true

	if not has_enter:
		errors.append("attackShoot must bind Enter")
	if not has_kp_enter:
		errors.append("attackShoot must bind Keypad Enter")

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)

