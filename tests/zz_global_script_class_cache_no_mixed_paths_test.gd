extends SceneTree

const CACHE_PATH: String = "res://.godot/global_script_class_cache.cfg"

const FORBIDDEN_SNIPPETS: Array[String] = [
	"res://Core//res://Game/",
	"res://Core//",
	"res://Game//",
	"res://core//res://game/",
	"res://core//",
	"res://game//",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []

	# The cache file may not exist in all headless modes.
	# When it exists, guard against mixed/invalid paths.
	if not FileAccess.file_exists(CACHE_PATH):
		_report(errors)
		return

	var content: String = FileAccess.get_file_as_string(CACHE_PATH)

	var offenders: Array[String] = []
	for snippet in FORBIDDEN_SNIPPETS:
		var idx: int = content.find(snippet)
		if idx == -1:
			continue
		var line_no: int = 1
		for i in range(idx):
			if content.unicode_at(i) == 10: # '\n'
				line_no += 1
		var line: String = content.split("\n")[line_no - 1]
		offenders.append("%s:%d: %s" % [CACHE_PATH, line_no, line])

	if offenders.size() > 0:
		errors.append(
			"global_script_class_cache.cfg must not contain mixed or double-slash paths. Found:\n%s" % "\n".join(offenders)
		)

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
