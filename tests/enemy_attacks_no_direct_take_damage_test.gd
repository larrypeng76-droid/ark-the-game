extends SceneTree

const ENEMY_DIR: String = "res://game/enemies"

const FORBIDDEN_TOKEN := ".take_damage("

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var offenders: Array[String] = []

	_scan_dir(ENEMY_DIR, offenders)
	if offenders.size() > 0:
		errors.append(
			"Enemy attack scripts must not call take_damage() directly; route via Hurtbox.hit(). Offenders:\n%s"
			% "\n".join(offenders)
		)

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

		var content: String = FileAccess.get_file_as_string(full_path)
		var lines: PackedStringArray = content.split("\n")
		for i in range(lines.size()):
			var line: String = lines[i]
			var trimmed: String = line.strip_edges()
			if trimmed.begins_with("#"):
				continue
			if line.find(FORBIDDEN_TOKEN) == -1:
				continue
			offenders.append("%s:%d: %s" % [full_path, i + 1, trimmed])
			break

		# Extra guard: EnemyBullet should not listen for Player body collisions directly
		# (avoid Player body vs HurtBox double-trigger). Terrain sensing is allowed.
		if full_path.ends_with("enemy_bullet.gd"):
			for i in range(lines.size()):
				var line: String = lines[i]
				var trimmed: String = line.strip_edges()
				if trimmed.begins_with("#"):
					continue
				if line.find("body_entered") == -1:
					continue
				var allowed: bool = line.find("terrain_sensor.") != -1 or line.find("_on_terrain_body_entered") != -1
				if allowed:
					continue
				offenders.append("%s:%d: %s" % [full_path, i + 1, trimmed])
				break

	dir.list_dir_end()

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)
