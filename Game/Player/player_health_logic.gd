extends RefCounted

func apply_damage(player: Node, amount: int) -> void:
	if amount <= 0:
		return
	if player.get("is_dead"):
		return

	var max_health_v = player.get("max_health")
	var health_v = player.get("health")
	var max_health: int = int(max_health_v) if typeof(max_health_v) == TYPE_INT else 0
	var health: int = int(health_v) if typeof(health_v) == TYPE_INT else 0

	health = clampi(health - amount, 0, max_health)
	player.set("health", health)

	if player.has_method("update_health_ui"):
		player.call("update_health_ui")

	if health <= 0 and player.has_method("die"):
		player.call("die")

