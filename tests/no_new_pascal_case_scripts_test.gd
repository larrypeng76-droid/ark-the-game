extends SceneTree

const DIRECTORIES: Array[String] = [
	"res://core",
	"res://game",
]

# Legacy allowlist (kept for future incremental migrations).
const LEGACY_ALLOWLIST: Array[String] = [
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var offenders: Array[String] = []

	for dir_path in DIRECTORIES:
		_scan_dir(dir_path, offenders)

	if offenders.size() > 0:
		errors.append("New scripts must use snake_case filenames. Unexpected PascalCase script(s):\n%s" % "\n".join(offenders))

	_report(errors)

func _scan_dir(dir_path: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue

		var full_path: String = "%s/%s" % [dir_path, name]
		if dir.current_is_dir():
			_scan_dir(full_path, offenders)
			continue

		if not name.ends_with(".gd"):
			continue

		var is_pascal_case: bool = name != name.to_lower()
		if not is_pascal_case:
			continue

		if full_path in LEGACY_ALLOWLIST:
			continue

		offenders.append(full_path)

	dir.list_dir_end()

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
