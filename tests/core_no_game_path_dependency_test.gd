extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var offenders: Array[String] = []
	_scan_dir_for_string("res://core", "res://game/", offenders)
	if offenders.size() > 0:
		errors.append("core/ must not reference res://game/. Offenders:\n%s" % "\n".join(offenders))
	_report(errors)

func _scan_dir_for_string(dir_path: String, needle: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		offenders.append("Failed to open dir: %s" % dir_path)
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
			_scan_dir_for_string(full_path, needle, offenders)
			continue

		if not name.ends_with(".gd"):
			continue

		var content: String = FileAccess.get_file_as_string(full_path)
		var idx: int = content.find(needle)
		if idx == -1:
			continue

		var line_no: int = 1
		# Compute 1-based line number for first occurrence.
		for i in range(idx):
			if content.unicode_at(i) == 10: # '\n'
				line_no += 1

		offenders.append("%s:%d" % [full_path, line_no])

	dir.list_dir_end()

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
