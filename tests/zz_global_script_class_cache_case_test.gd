extends SceneTree

const CACHE_PATH: String = "res://.godot/global_script_class_cache.cfg"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	# The cache file may not exist if there are currently no global script classes.
	# When it exists, it must never reference legacy-cased paths.
	if not FileAccess.file_exists(CACHE_PATH):
		_report(errors)
		return

	var content: String = FileAccess.get_file_as_string(CACHE_PATH)
	var offenders: Array[String] = []
	_append_if_found(content, "res://Core/", offenders)
	_append_if_found(content, "res://Game/", offenders)

	if offenders.size() > 0:
		errors.append(
			"global_script_class_cache.cfg must not contain legacy-cased paths (res://Core/, res://Game/). Found:\n%s"
			% "\n".join(offenders)
		)

	_report(errors)

func _append_if_found(content: String, needle: String, offenders: Array[String]) -> void:
	var idx: int = content.find(needle)
	if idx == -1:
		return

	var line_no: int = 1
	for i in range(idx):
		if content.unicode_at(i) == 10: # n
			line_no += 1
	var line: String = content.split("\n")[line_no - 1]
	offenders.append("%s:%d: %s" % [CACHE_PATH, line_no, line])

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
