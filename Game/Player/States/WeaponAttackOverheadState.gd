# res://Game/Player/States/WeaponAttackOverheadState.gd

extends PlayerState

class_name WeaponAttackOverheadState

var elapsed: float = 0.0
var max_duration: float = 0.75

func enter(_player: Player):
	
	super.enter(_player)
	
	player.velocity.x = 0
	
	player.is_attacking = true
	player.play_animation("weapon-attack-overhead")
	elapsed = 0.0
	max_duration = _get_animation_duration("weapon-attack-overhead", 0.6) + 0.05
		
func on_animation_finished(_animation: StringName):
	if _animation == "weapon-attack-overhead":
		
		player.is_attacking = false;
		
		if not player.is_on_floor():
			player.state_machine.change_state("FallState")
		elif player.direction != 0.0 and not player.is_crouched:
			player.state_machine.change_state("RunState")
		elif player.is_crouched:
			player.state_machine.change_state("IdleCrouchState")
		else:
			player.state_machine.change_state("IdleState")
	
func process_update(_delta):
	elapsed += _delta
	if elapsed >= max_duration:
		on_animation_finished("weapon-attack-overhead")
		

func physics_update(_delta):
	pass

func exit():
	player.is_attacking = false

func _get_animation_duration(name: StringName, fallback: float) -> float:
	var anim: Animation = player.animation_player.get_animation(name)
	if anim:
		return anim.length
	return fallback
		
