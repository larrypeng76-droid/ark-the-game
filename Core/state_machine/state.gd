# res://core/state_machine/state.gd

extends Node

class_name State

var host: Node

func enter(new_host: Node) -> void:
	host = new_host

func exit() -> void:
	pass

func process_update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
