# res://Core/Combat/Hurtbox.gd

extends Area2D

class_name Hurtbox

func hit(damage, _damaged_by) -> void:
	var enemy_root := get_parent()
	if not is_instance_valid(enemy_root):
		return
	
	var amount: int = 1
	if damage is int:
		amount = damage
	elif damage is float:
		amount = int(damage)
	
	if amount <= 0:
		return
	
	if enemy_root.has_method("take_damage"):
		enemy_root.take_damage(amount)
	else:
		enemy_root.queue_free()
