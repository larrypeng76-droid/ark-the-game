extends CanvasLayer

class_name TransitionManager

@onready var fade: ColorRect = ColorRect.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	layer = 100   # draw on top

func fade_out() -> void:
	await _fade(1.0)

func fade_in() -> void:
	await _fade(0.0)

func _fade(target_alpha: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "modulate:a", target_alpha, 0.5)
	await t.finished
