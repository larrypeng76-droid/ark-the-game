extends Control

func _on_play_pressed() -> void:
	await GameFlow.restart_game()
