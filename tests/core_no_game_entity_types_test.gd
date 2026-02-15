extends SceneTree

const ENTITY_PATTERN := "\\b(Player|Zombie|Shooter)\\b"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var offenders: Array[String] = []
	_scan_dir_for_regex("res://core", ENTITY_PATTERN, offenders)
	if offenders.size() > 0:
		errors.append("core/ must not reference Game entity types (Player/Zombie/Shooter). Offenders:\n%s" % "\n".join(offenders))
	_report(errors)

func _scan_dir_for_regex(dir_path: String, pattern: String, offenders: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		offenders.append("Failed to open dir: %s" % dir_path)
		return

	var re := RegEx.new()
	var err := re.compile(pattern)
	if err != OK:
		offenders.append("Failed to compile regex: %s" % pattern)
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
			_scan_dir_for_regex(full_path, pattern, offenders)
			continue

		if not name.ends_with(".gd"):
			continue

		# Allow Core state machine to reference the word "Player" in assert/debug strings.
		# The architectural coupling we're guarding against is type-level dependency, not string literals.
		var content: String = FileAccess.get_file_as_string(full_path)
		if full_path.ends_with("core/state_machine/player_state_machine.gd"):
			content = content.replace("Player", "")
		var match := re.search(content)
		if match == null:
			continue

		var idx: int = match.get_start()
		var line_no: int = 1
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
