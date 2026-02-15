extends SceneTree

const FILES: Array[String] = [
	"res://game/enemies/enemy_bullet.gd",
	"res://game/enemies/shooter.gd",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: Array[String] = []
	var offenders: Array[String] = []

	for path in FILES:
		var content: String = FileAccess.get_file_as_string(path)
		if content.find("is Player") != -1:
			offenders.append(path)

	if offenders.size() > 0:
		errors.append("Enemy attack scripts should not hard-depend on Player type checks ('is Player'). Offenders:\n%s" % "\n".join(offenders))

	_report(errors)

func _report(errors: Array[String]) -> void:
	if errors.size() > 0:
		for e in errors:
			push_error(e)
		quit(1)
		return
	quit(0)

