extends RefCounted

const PlayerBulletScene := preload("res://game/player/player_bullet.tscn")

func fire_bullet(player: Node, aim_global_position: Callable, bullet_speed: float) -> void:
	var bullet := PlayerBulletScene.instantiate()
	player.get_tree().current_scene.add_child(bullet)
	var player_2d: Node2D = player as Node2D
	if player.has_method("get_bullet_spawn_global_position"):
		bullet.global_position = player.call("get_bullet_spawn_global_position")
	else:
		bullet.global_position = player_2d.global_position

	var target: Vector2
	var result: Variant = aim_global_position.call()
	if result is Vector2:
		target = result
	else:
		target = player_2d.global_position + Vector2.RIGHT

	var dir: Vector2 = (target - bullet.global_position)
	if bullet.has_method("setup_direction"):
		bullet.setup_direction(dir, bullet_speed)
	elif bullet.has_method("setup"):
		bullet.setup(signf(dir.x), bullet_speed)

func is_enemy_in_melee_range(player: Node2D, melee_range: float) -> bool:
	var enemies: Array = player.get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return false
	var range_sq: float = melee_range * melee_range
	for enemy in enemies:
		if enemy is Node2D:
			var enemy_node: Node2D = enemy
			var dist_sq: float = enemy_node.global_position.distance_squared_to(player.global_position)
			if dist_sq <= range_sq:
				return true
	return false
