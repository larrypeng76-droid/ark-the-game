extends SceneTree

const CORE_PLAYER_STATE: String = "res://core/state_machine/player_state.gd"
const CORE_PLAYER_STATE_MACHINE: String = "res://core/state_machine/player_state_machine.gd"

const GAME_PLAYER_STATE: String = "res://game/player/player_state.gd"
const GAME_PLAYER_STATE_MACHINE: String = "res://game/player/player_state_machine.gd"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	# Enforce strict Core -> Game layering: Player-specific state code lives in game/.
	if FileAccess.file_exists(CORE_PLAYER_STATE):
		errors.append("PlayerState must not live in core/: %s" % CORE_PLAYER_STATE)
	if FileAccess.file_exists(CORE_PLAYER_STATE_MACHINE):
		errors.append("PlayerStateMachine must not live in core/: %s" % CORE_PLAYER_STATE_MACHINE)

	if not FileAccess.file_exists(GAME_PLAYER_STATE):
		errors.append("Missing PlayerState in game/: %s" % GAME_PLAYER_STATE)
	if not FileAccess.file_exists(GAME_PLAYER_STATE_MACHINE):
		errors.append("Missing PlayerStateMachine in game/: %s" % GAME_PLAYER_STATE_MACHINE)

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)

