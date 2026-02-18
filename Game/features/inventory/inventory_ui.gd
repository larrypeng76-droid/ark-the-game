extends CanvasLayer

signal item_requested_use(item_id: String)
signal magazine_reload_requested

const ITEM_APPLE := "apple"
const ITEM_PICKAXE := "pickaxe"
const ITEM_AXE := "axe"
const ITEM_GROUND_BLOCK := "ground_block"
const ITEM_WOOD := "wood"
const SLOT_COUNT := 9
const ICON_SIZE := 10.0
const SLOT_MAGAZINE := 0
const SLOT_APPLE := 1
const SLOT_PICKAXE := 2
const SLOT_AXE := 3
const SLOT_GROUND_BLOCK := 4
const SLOT_WOOD := 5

@export var columns: int = 3

@onready var root_control: Control = $Root
@onready var grid: GridContainer = $Root/InventoryPanel/CenterContainer/GridContainer

var _counts: Dictionary = {}
var _slot_buttons: Array[Button] = []
var _slot_icons: Array[TextureRect] = []
var _slot_counts: Array[Label] = []
var _slot_aux_counts: Array[Label] = []

var _apple_icon: Texture2D
var _magazine_icon: Texture2D
var _pickaxe_icon: Texture2D
var _axe_icon: Texture2D
var _ground_block_icon: Texture2D
var _wood_icon: Texture2D

var _ammo_in_mag: int = 0
var _spare_mags: int = 0
var _is_reloading: bool = false
var _reload_time_left: float = 0.0


func _ready() -> void:
	add_to_group("inventory_ui")
	call_deferred("_sync_root_to_viewport")
	get_viewport().size_changed.connect(_sync_root_to_viewport)
	_add_slots_if_missing()
	_apple_icon = load("res://game/features/items/apple/apple_icon.svg") as Texture2D
	_magazine_icon = _create_magazine_icon_texture()
	_pickaxe_icon = _create_pickaxe_icon_texture()
	_axe_icon = _create_axe_icon_texture()
	_ground_block_icon = _create_ground_block_icon_texture()
	_wood_icon = _create_wood_icon_texture()
	# Must be usable both during gameplay and while paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_connect_player_signals")
	_update_ui()


func _create_magazine_icon_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Simple magazine silhouette.
	for y in range(2, 15):
		for x in range(5, 11):
			img.set_pixel(x, y, Color(0.92, 0.92, 0.92, 1.0))
	for y in range(4, 13):
		for x in range(6, 10):
			img.set_pixel(x, y, Color(0.65, 0.65, 0.65, 1.0))
	for y in range(13, 15):
		for x in range(6, 10):
			img.set_pixel(x, y, Color(0.55, 0.55, 0.55, 1.0))

	return ImageTexture.create_from_image(img)


func _create_pickaxe_icon_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(4, 13):
		for x in range(7, 9):
			img.set_pixel(x, y, Color(0.46, 0.24, 0.11, 1.0))
	for y in range(2, 6):
		for x in range(3, 13):
			img.set_pixel(x, y, Color(0.72, 0.72, 0.78, 1.0))

	return ImageTexture.create_from_image(img)


func _create_ground_block_icon_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(3, 13):
		for x in range(3, 13):
			img.set_pixel(x, y, Color(0.52, 0.35, 0.24, 1.0))

	for x in range(3, 13):
		img.set_pixel(x, 3, Color(0.62, 0.45, 0.31, 1.0))
		img.set_pixel(x, 12, Color(0.37, 0.24, 0.16, 1.0))

	for y in range(3, 13):
		img.set_pixel(3, y, Color(0.62, 0.45, 0.31, 1.0))
		img.set_pixel(12, y, Color(0.37, 0.24, 0.16, 1.0))

	return ImageTexture.create_from_image(img)


func _create_axe_icon_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(5, 14):
		for x in range(7, 9):
			img.set_pixel(x, y, Color(0.46, 0.24, 0.11, 1.0))

	for y in range(3, 8):
		for x in range(3, 11):
			img.set_pixel(x, y, Color(0.72, 0.72, 0.78, 1.0))

	for y in range(4, 7):
		for x in range(2, 4):
			img.set_pixel(x, y, Color(0.66, 0.66, 0.72, 1.0))

	return ImageTexture.create_from_image(img)


func _create_wood_icon_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for y in range(4, 12):
		for x in range(3, 13):
			img.set_pixel(x, y, Color(0.54, 0.36, 0.21, 1.0))

	for x in range(3, 13):
		img.set_pixel(x, 4, Color(0.63, 0.44, 0.27, 1.0))
		img.set_pixel(x, 11, Color(0.42, 0.27, 0.15, 1.0))

	return ImageTexture.create_from_image(img)


func _connect_player_signals() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.has_signal("ammo_state_changed"):
		var callable := Callable(self, "_on_player_ammo_state_changed")
		if not player.is_connected("ammo_state_changed", callable):
			player.connect("ammo_state_changed", callable)
	# Pull initial state if available.
	if player.has_method("get_ammo_state"):
		var state: Variant = player.call("get_ammo_state")
		if state is Dictionary:
			_on_player_ammo_state_changed(
				int(state.get("ammo_in_mag", 0)),
				int(state.get("spare_mags", 0)),
				bool(state.get("is_reloading", false)),
				float(state.get("reload_time_left", 0.0))
			)


func _on_player_ammo_state_changed(ammo_in_mag: int, spare_mags: int, is_reloading: bool, reload_time_left: float) -> void:
	_ammo_in_mag = ammo_in_mag
	_spare_mags = spare_mags
	_is_reloading = is_reloading
	_reload_time_left = reload_time_left
	_update_ui()


func _sync_root_to_viewport() -> void:
	# CanvasLayer is not a Control and doesn't provide a layout rect. We keep a
	# full-screen Control as the layout root so anchors/offsets behave correctly
	# in both the editor preview and in-game with stretch/letterboxing.
	if root_control == null:
		return
	root_control.position = Vector2.ZERO
	root_control.size = get_viewport().get_visible_rect().size


func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	_counts[item_id] = int(_counts.get(item_id, 0)) + amount
	_update_ui()


func get_count(item_id: String) -> int:
	return int(_counts.get(item_id, 0))


func consume_one(item_id: String) -> bool:
	var current: int = int(_counts.get(item_id, 0))
	if current <= 0:
		return false
	current -= 1
	if current <= 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = current
	_update_ui()
	return true


func _add_slots_if_missing() -> void:
	grid.columns = columns

	# If the scene already contains the slots (e.g. opened in editor), just wire them.
	if grid.get_child_count() >= SLOT_COUNT:
		_wire_existing_slots()
		return

	for i in range(SLOT_COUNT):
		var button := Button.new()
		button.name = "Slot%d" % i
		button.custom_minimum_size = Vector2(15, 15)
		button.pressed.connect(_on_slot_pressed.bind(i))
		grid.add_child(button)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# 10x10 icon centered in the slot.
		icon.anchor_left = 0.5
		icon.anchor_top = 0.5
		icon.anchor_right = 0.5
		icon.anchor_bottom = 0.5
		icon.offset_left = -5.0
		icon.offset_top = -5.0
		icon.offset_right = 5.0
		icon.offset_bottom = 5.0
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)

		var count_label := Label.new()
		count_label.name = "Count"
		count_label.anchor_left = 0.0
		count_label.anchor_top = 0.0
		count_label.anchor_right = 1.0
		count_label.anchor_bottom = 1.0
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.add_theme_font_size_override("font_size", 4)
		count_label.offset_right = -1.0
		count_label.offset_bottom = -1.0
		button.add_child(count_label)

		_slot_buttons.append(button)
		_slot_icons.append(icon)
		_slot_counts.append(count_label)

		var aux_label := Label.new()
		aux_label.name = "AuxCount"
		aux_label.anchor_left = 0.0
		aux_label.anchor_top = 0.0
		aux_label.anchor_right = 1.0
		aux_label.anchor_bottom = 1.0
		aux_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		aux_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		aux_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aux_label.add_theme_font_size_override("font_size", 4)
		aux_label.offset_left = 1.0
		aux_label.offset_top = 1.0
		button.add_child(aux_label)
		_slot_aux_counts.append(aux_label)


func _wire_existing_slots() -> void:
	_slot_buttons.clear()
	_slot_icons.clear()
	_slot_counts.clear()
	_slot_aux_counts.clear()

	for i in range(mini(SLOT_COUNT, grid.get_child_count())):
		var button := grid.get_child(i) as Button
		if button == null:
			continue
		button.custom_minimum_size = Vector2(15, 15)
		button.clip_contents = true
		button.pressed.connect(_on_slot_pressed.bind(i))
		_slot_buttons.append(button)
		var icon := button.get_node_or_null("Icon") as TextureRect
		if icon != null:
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.anchor_left = 0.5
			icon.anchor_top = 0.5
			icon.anchor_right = 0.5
			icon.anchor_bottom = 0.5
			icon.offset_left = -ICON_SIZE * 0.5
			icon.offset_top = -ICON_SIZE * 0.5
			icon.offset_right = ICON_SIZE * 0.5
			icon.offset_bottom = ICON_SIZE * 0.5
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot_icons.append(icon)

		var count_label := button.get_node_or_null("Count") as Label
		if count_label != null:
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			count_label.add_theme_font_size_override("font_size", 4)
			count_label.offset_right = -1.0
			count_label.offset_bottom = -1.0
		_slot_counts.append(count_label)

		var aux_label := button.get_node_or_null("AuxCount") as Label
		if aux_label == null:
			aux_label = Label.new()
			aux_label.name = "AuxCount"
			button.add_child(aux_label)
		aux_label.anchor_left = 0.0
		aux_label.anchor_top = 0.0
		aux_label.anchor_right = 1.0
		aux_label.anchor_bottom = 1.0
		aux_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		aux_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		aux_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aux_label.add_theme_font_size_override("font_size", 4)
		aux_label.offset_left = 1.0
		aux_label.offset_top = 1.0
		_slot_aux_counts.append(aux_label)


func _update_ui() -> void:
	var apple_count: int = get_count(ITEM_APPLE)
	var pickaxe_count: int = get_count(ITEM_PICKAXE)
	var axe_count: int = get_count(ITEM_AXE)
	var ground_block_count: int = get_count(ITEM_GROUND_BLOCK)
	var wood_count: int = get_count(ITEM_WOOD)
	for i in range(_slot_buttons.size()):
		var icon := _slot_icons[i]
		var label := _slot_counts[i]
		var aux_label: Label = _slot_aux_counts[i] if i < _slot_aux_counts.size() else null
		var button: Button = _slot_buttons[i]
		if icon:
			if i == SLOT_MAGAZINE:
				icon.texture = _magazine_icon
			elif i == SLOT_APPLE and apple_count > 0:
				icon.texture = _apple_icon
			elif i == SLOT_PICKAXE and pickaxe_count > 0:
				icon.texture = _pickaxe_icon
			elif i == SLOT_AXE and axe_count > 0:
				icon.texture = _axe_icon
			elif i == SLOT_GROUND_BLOCK and ground_block_count > 0:
				icon.texture = _ground_block_icon
			elif i == SLOT_WOOD and wood_count > 0:
				icon.texture = _wood_icon
			else:
				icon.texture = null
		if label:
			if i == SLOT_MAGAZINE:
				if _is_reloading:
					label.text = "%.1f" % maxf(_reload_time_left, 0.0)
				else:
					label.text = str(_ammo_in_mag)
			elif i == SLOT_APPLE and apple_count > 1:
				label.text = str(apple_count)
			elif i == SLOT_PICKAXE and pickaxe_count > 1:
				label.text = str(pickaxe_count)
			elif i == SLOT_AXE and axe_count > 1:
				label.text = str(axe_count)
			elif i == SLOT_GROUND_BLOCK and ground_block_count > 1:
				label.text = str(ground_block_count)
			elif i == SLOT_WOOD and wood_count > 1:
				label.text = str(wood_count)
			else:
				label.text = ""
		if aux_label:
			if i == SLOT_MAGAZINE:
				var total_mags_left: int = _spare_mags + (1 if (_ammo_in_mag > 0 or _is_reloading) else 0)
				aux_label.text = str(total_mags_left) if total_mags_left > 0 else ""
			else:
				aux_label.text = ""
		if button:
			if i == SLOT_MAGAZINE:
				button.disabled = _is_reloading or _ammo_in_mag > 0 or _spare_mags <= 0
			elif i == SLOT_APPLE:
				button.disabled = apple_count <= 0
			elif i == SLOT_PICKAXE:
				button.disabled = pickaxe_count <= 0
			elif i == SLOT_AXE:
				button.disabled = axe_count <= 0
			elif i == SLOT_GROUND_BLOCK:
				button.disabled = ground_block_count <= 0 or not _can_use_items()
			elif i == SLOT_WOOD:
				button.disabled = true
			else:
				button.disabled = true


func _on_slot_pressed(slot_index: int) -> void:
	if slot_index == SLOT_MAGAZINE:
		magazine_reload_requested.emit()
		return
	if slot_index == SLOT_PICKAXE:
		if get_count(ITEM_PICKAXE) > 0:
			item_requested_use.emit(ITEM_PICKAXE)
		return
	if slot_index == SLOT_AXE:
		if get_count(ITEM_AXE) > 0:
			item_requested_use.emit(ITEM_AXE)
		return
	if slot_index == SLOT_GROUND_BLOCK:
		if not _can_use_items():
			return
		if get_count(ITEM_GROUND_BLOCK) <= 0:
			return
		item_requested_use.emit(ITEM_GROUND_BLOCK)
		return

	if slot_index != SLOT_APPLE:
		return
	if not _can_use_items():
		return
	if get_count(ITEM_APPLE) <= 0:
		return
	# Consume first so the UI updates even if nobody is listening.
	if consume_one(ITEM_APPLE):
		item_requested_use.emit(ITEM_APPLE)
		# Fallback: if nobody is connected (common when scene _ready() order differs),
		# apply the effect directly.
		if get_signal_connection_list("item_requested_use").is_empty():
			_apply_item_effect_locally(ITEM_APPLE)
		if OS.is_debug_build():
			print("InventoryUI: used apple")


func _apply_item_effect_locally(item_id: String) -> void:
	if item_id != ITEM_APPLE:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if bool(player.get("is_dead")):
		return
	if player.has_method("heal"):
		player.call("heal", 1)


func _can_use_items() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return true
	return not bool(player.get("is_dead"))
