# res://core/combat/combat_effects.gd

extends Node

class_name CombatEffects

static func apply_hit_effects(
	target: Node,
	from_position: Vector2,
	knockback_distance: float,
	screen_shake_amount: float,
	screen_shake_duration: float
) -> void:
	if not is_instance_valid(target):
		return

	if knockback_distance > 0.0 and target.has_method("apply_knockback"):
		target.call("apply_knockback", from_position, knockback_distance)

	if screen_shake_amount > 0.0 and screen_shake_duration > 0.0 and target.has_method("shake_camera"):
		target.call("shake_camera", screen_shake_amount, screen_shake_duration)
