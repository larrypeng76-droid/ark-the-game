# res://game/flow/game_flow_manager.gd

extends Node

class_name GameFlowManager

const TransitionManagerScript := preload("res://core/ui/transition_manager.gd")

const GAME_SCENE_PATH: String = "res://game/game.tscn"
const MENU_SCENE_PATH: String = "res://game/main_menu.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func set_paused(paused: bool) -> void:
	get_tree().paused = paused

func change_scene(scene_path: String, with_fade: bool = true) -> void:
	if with_fade:
		var transition_manager := TransitionManagerScript.new()
		get_tree().root.add_child(transition_manager)
		await transition_manager.fade_out()
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame
		await transition_manager.fade_in()
		transition_manager.queue_free()
		return

	get_tree().change_scene_to_file(scene_path)

func restart_game() -> void:
	get_tree().paused = false
	await change_scene(GAME_SCENE_PATH, true)

func go_to_main_menu() -> void:
	get_tree().paused = false
	await change_scene(MENU_SCENE_PATH, true)
