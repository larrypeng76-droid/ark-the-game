extends SceneTree

const CACHE_PATH: String = "res://.godot/global_script_class_cache.cfg"

const EXPECTED_CLASSES: Dictionary = {
	"Hitbox": "res://core/combat/hitbox.gd",
	"Hurtbox": "res://core/combat/hurtbox.gd",
	"TransitionManager": "res://core/ui/transition_manager.gd",
	"DeathScreen": "res://core/ui/death_screen.gd",
	"GameFlowManager": "res://game/flow/game_flow_manager.gd",
	"State": "res://core/state_machine/state.gd",
	"StateMachine": "res://core/state_machine/state_machine.gd",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	# Godot may not generate this cache file in all headless modes.
	# When it exists (e.g. after editor runs), enforce casing + entries.
	if not FileAccess.file_exists(CACHE_PATH):
		_report(errors)
		return

	var content: String = FileAccess.get_file_as_string(CACHE_PATH)

	if content.find("res://Core/") != -1 or content.find("res://Game/") != -1:
		errors.append("global_script_class_cache.cfg contains legacy-cased paths (res://Core/ or res://Game/).")

	for expected_class in EXPECTED_CLASSES.keys():
		var expected_path: String = EXPECTED_CLASSES[expected_class]
		var class_token: String = "\"class\": &\"%s\"" % expected_class
		var path_token: String = "\"path\": \"%s\"" % expected_path
		if content.find(class_token) == -1:
			errors.append("Cache missing class entry: %s" % expected_class)
		if content.find(path_token) == -1:
			errors.append("Cache missing expected path for %s: %s" % [expected_class, expected_path])

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
