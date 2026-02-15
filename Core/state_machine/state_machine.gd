# res://core/state_machine/state_machine.gd

extends Node

class_name StateMachine

signal state_changed(new_state_name: String)

var host: Node
var states: Dictionary = {}
var current_state

func _ready() -> void:
	host = get_parent()
	assert(host != null, "StateMachine must have a host parent")

	for child in get_children():
		states[child.name] = child

func change_state(new_state_name: String) -> void:
	if current_state and current_state.name == str(new_state_name):
		return

	if current_state:
		current_state.exit()

	if states.has(new_state_name):
		current_state = states[new_state_name]
		state_changed.emit(new_state_name)
		if current_state:
			current_state.enter(host)
	else:
		print_debug("State: %s does not exist" % new_state_name)

func process_update(delta: float) -> void:
	if current_state:
		current_state.process_update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
