extends SceneTree

const TEST_SCENE_PATH := "res://game/game.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: Array[String] = []

	var packed := load(TEST_SCENE_PATH) as PackedScene
	if packed == null:
		errors.append("Failed to load %s" % TEST_SCENE_PATH)
		_report(errors)
		return

	var root_node := packed.instantiate()
	root_node.name = "TestRoot"
	root_node.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_root().add_child(root_node)
	await process_frame

	var player := root_node.get_node_or_null("Player")
	if player == null:
		errors.append("Expected node Player")
		_report(errors)
		return

	var inventory_ui := root_node.get_node_or_null("InventoryUI")
	if inventory_ui == null:
		errors.append("Expected node InventoryUI")
		_report(errors)
		return

	# Simulate pickup (avoid physics in headless test).
	if inventory_ui.has_method("add_item"):
		inventory_ui.call("add_item", "apple", 2)
	else:
		errors.append("InventoryUI missing add_item")

	if inventory_ui.has_method("get_count"):
		var count: int = int(inventory_ui.call("get_count", "apple"))
		if count != 2:
			errors.append("Expected 2 apples, got %d" % count)
	else:
		errors.append("InventoryUI missing get_count")

	# Damage player then use an apple.
	player.set("health", 5)
	if player.has_method("update_health_ui"):
		player.call("update_health_ui")

	# Simulate UI consumption + emission.
	if inventory_ui.has_method("consume_one"):
		inventory_ui.call("consume_one", "apple")
	else:
		errors.append("InventoryUI missing consume_one")

	if player.has_method("_on_inventory_item_use_requested"):
		player.call("_on_inventory_item_use_requested", "apple")
	else:
		errors.append("Player missing inventory use handler")

	var health: int = int(player.get("health"))
	if health != 6:
		errors.append("Expected health 6 after use, got %d" % health)

	var remaining: int = 0
	if inventory_ui.has_method("get_count"):
		remaining = int(inventory_ui.call("get_count", "apple"))
	if remaining != 1:
		errors.append("Expected 1 apple remaining, got %d" % remaining)

	root_node.queue_free()
	_report(errors)


func _report(errors: Array[String]) -> void:
	for e in errors:
		push_error(e)
	quit(0 if errors.is_empty() else 1)
