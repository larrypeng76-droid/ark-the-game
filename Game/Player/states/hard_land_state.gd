# res://game/player/states/hard_land_state.gd

extends "res://game/player/player_state.gd"

var timer: SceneTreeTimer
var timer_callable: Callable

func enter(_player) -> void:
	super.enter(_player)
	
	player.sheave_weapon()
	player.set_collision_shape(player.collision_shapes.STANDING)
	player.play_animation("hard-land")
	
	timer = get_tree().create_timer(player.hard_land_run_time)
	timer_callable = Callable(self, "_end")
	timer.timeout.connect(timer_callable, CONNECT_ONE_SHOT)
	
func process_update(_delta):
	pass

func physics_update(_delta):
	
	player.velocity.x = player.apply_deacceleration_in_x_on_ground(_delta)
	if not player.is_on_floor():
		player.state_machine.change_state("FallState")
		return
	
func _end():
	if player.is_on_floor(): 
		player.jumps = 0
		player.state_machine.change_state("IdleState")
	else:
		player.state_machine.change_state("FallState")

func exit():
	if timer and timer_callable.is_valid():
		if timer.timeout.is_connected(timer_callable):
			timer.timeout.disconnect(timer_callable)
	timer = null
	timer_callable = Callable()
