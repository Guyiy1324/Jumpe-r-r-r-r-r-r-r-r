extends Control

signal back
signal playtest(level: RefCounted)

const Level := preload("res://Scripts/jumper/level_data.gd")
const UI := preload("res://Scripts/jumper/interface.gd")
const Grid := preload("res://Scripts/jumper/editor_grid.gd")
const Preview := preload("res://Scripts/jumper/tile_preview.gd")
const BRUSHES := [Level.GRASS, Level.STONE, Level.SPIKES, Level.SPRING, Level.COIN, Level.START, Level.EXIT, Level.EMPTY]
const NAMES := ["Grass", "Stone", "Spikes", "Spring", "Coin", "Spawn", "Exit", "Eraser"]
const DESCRIPTIONS := [
	"Solid ground", "Solid walls", "Respawn hazard", "Launch pad", "Optional pickup", "Starting point", "Finish portal", "Remove a tile",
]

var slots: Array[Dictionary] = []
var slot := 0
var grid: Control
var title_field: LineEdit
var slot_menu: OptionButton
var status: Label
var save_state: Label
var play_button: Button
var undo_button: Button
var redo_button: Button
var palette: Array[Button] = []
var stroke_before := PackedByteArray()
var window := ConfirmationDialog.new()


func _ready() -> void:
	for i in 3:
		var level: RefCounted
		var path := _path(i)
		if FileAccess.file_exists(path):
			level = Level.decode(JSON.parse_string(FileAccess.get_file_as_string(path)))
		var loaded := level != null
		if not loaded:
			level = Level.starter()
		slots.append({"level": level, "baseline": level.encode(), "saved": loaded, "undo": [], "redo": []})
	_build()
	_select_slot(0)


func _path(index: int) -> String:
	return "user://jumper_workshop_%d.json" % (index + 1)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = UI.INK
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := UI.margins(self, 24, 20)
	var layout := UI.vbox(13)
	frame.add_child(layout)
	var header := UI.hbox(14)
	layout.add_child(header)
	header.add_child(UI.button("‹   Menu", func(): back.emit()))
	var names := UI.vbox(4)
	header.add_child(names)
	names.add_child(UI.label("JUMPER JUMP", 10, UI.MINT, true))
	names.add_child(UI.label("Level Workshop", 28))
	header.add_child(UI.spacer())
	save_state = UI.label("", 14, UI.MUTED)
	header.add_child(save_state)
	header.add_child(UI.button("Save level", _save))
	play_button = UI.button("Playtest", _playtest, true)
	play_button.custom_minimum_size.x = 115
	header.add_child(play_button)

	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(row)
	var sidebar := UI.panel(UI.PANEL, UI.LINE, 11)
	sidebar.custom_minimum_size.x = 208
	row.add_child(sidebar)
	var tools := UI.vbox(5)
	sidebar.add_child(tools)
	tools.add_child(UI.label("TILE PALETTE", 9, UI.MINT, true))
	for i in BRUSHES.size():
		var pick := UI.button("", _select_brush.bind(i), false, 47)
		pick.toggle_mode = true
		pick.focus_mode = Control.FOCUS_NONE
		pick.tooltip_text = "%s · %s" % [NAMES[i], DESCRIPTIONS[i]]
		tools.add_child(pick)
		palette.append(pick)
		var item := UI.margins(pick, 10, 5)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var parts := UI.hbox(8)
		parts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(parts)
		var preview := Preview.new()
		preview.tile = BRUSHES[i]
		preview.custom_minimum_size = Vector2(25, 25)
		preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parts.add_child(preview)
		var copy := UI.vbox(0)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(UI.label(NAMES[i], 15))
		copy.add_child(UI.label(DESCRIPTIONS[i], 11, UI.MUTED))
		parts.add_child(copy)
		parts.add_child(UI.spacer())
		parts.add_child(UI.label(str(i + 1), 12, UI.MINT))
	tools.add_child(UI.spacer(true))
	tools.add_child(UI.button("Clear grid…", _confirm_clear, false, 34))
	_select_brush(0)

	var workspace := UI.vbox(9)
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(workspace)
	var bar := UI.hbox(8)
	workspace.add_child(bar)
	slot_menu = OptionButton.new()
	slot_menu.custom_minimum_size = Vector2(108, 38)
	for i in 3:
		slot_menu.add_item("Slot %d" % (i + 1))
	slot_menu.item_selected.connect(_select_slot)
	bar.add_child(slot_menu)
	title_field = LineEdit.new()
	title_field.placeholder_text = "Level name"
	title_field.max_length = 32
	title_field.custom_minimum_size.x = 130
	title_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_field.text_changed.connect(_rename)
	title_field.text_submitted.connect(func(_name): title_field.release_focus())
	bar.add_child(title_field)
	undo_button = UI.button("Undo", _undo, false, 38)
	redo_button = UI.button("Redo", _redo, false, 38)
	bar.add_child(undo_button)
	bar.add_child(redo_button)
	var grid_toggle := UI.button("Grid", Callable(), false, 38)
	grid_toggle.toggle_mode = true
	grid_toggle.set_pressed_no_signal(true)
	grid_toggle.toggled.connect(func(enabled): grid.show_grid = enabled; grid.queue_redraw())
	bar.add_child(grid_toggle)
	bar.add_child(UI.button("−", _zoom.bind(1.0 / 1.25), false, 38))
	bar.add_child(UI.button("+", _zoom.bind(1.25), false, 38))
	bar.add_child(UI.button("Fit", func(): grid.reset_view(), false, 38))

	var board := UI.panel(UI.INK, UI.LINE, 2)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(board)
	grid = Grid.new()
	grid.stroke_started.connect(_start_stroke)
	grid.tile_painted.connect(_paint)
	board.add_child(grid)
	var info := UI.hbox(8)
	workspace.add_child(info)
	status = UI.label("", 14, UI.MUTED)
	info.add_child(status)
	info.add_child(UI.spacer())
	info.add_child(UI.label("40 × 20 tiles", 14, UI.MUTED))
	var foot := UI.hbox(8)
	layout.add_child(foot)
	for hint in ["Left drag   Paint", "Right drag   Erase", "Middle drag   Pan", "Scroll   Zoom", "1–8   Brush", "F5   Playtest"]:
		foot.add_child(UI.key_hint(hint))
	add_child(window)
	window.title = "Clear the grid?"
	window.dialog_text = "All tiles in this slot will be removed. You can undo this."
	window.ok_button_text = "Clear grid"
	window.confirmed.connect(_clear)


func _select_slot(index: int) -> void:
	slot = index
	grid.level = slots[slot].level
	title_field.text = grid.level.title
	grid.queue_redraw()
	_update_status()


func _select_brush(index: int) -> void:
	for i in palette.size():
		palette[i].set_pressed_no_signal(i == index)
	if is_instance_valid(grid):
		grid.brush = BRUSHES[index]


func _rename(copy: String) -> void:
	grid.level.title = copy.strip_edges() if not copy.strip_edges().is_empty() else "Untitled level"
	_update_status()


func _start_stroke() -> void:
	stroke_before = grid.level.cells.duplicate()


func _paint(cell: Vector2i, tile: int) -> void:
	if grid.level.tile_at(cell) == tile:
		return
	if not stroke_before.is_empty():
		_remember(stroke_before)
		stroke_before = PackedByteArray()
	grid.level.paint(cell, tile)
	_update_status()


func _remember(cells: PackedByteArray) -> void:
	var undo: Array = slots[slot].undo
	undo.append(cells)
	if undo.size() > 100:
		undo.pop_front()
	slots[slot].redo.clear()


func _undo() -> void:
	var undo: Array = slots[slot].undo
	if undo.is_empty():
		return
	slots[slot].redo.append(grid.level.cells.duplicate())
	grid.level.cells = undo.pop_back()
	grid.queue_redraw()
	_update_status()


func _redo() -> void:
	var redo: Array = slots[slot].redo
	if redo.is_empty():
		return
	slots[slot].undo.append(grid.level.cells.duplicate())
	grid.level.cells = redo.pop_back()
	grid.queue_redraw()
	_update_status()


func _confirm_clear() -> void:
	window.popup_centered(Vector2i(400, 144))


func _clear() -> void:
	if grid.level.cells.count(Level.EMPTY) == grid.level.cells.size():
		return
	_remember(grid.level.cells.duplicate())
	grid.level.cells.fill(Level.EMPTY)
	grid.queue_redraw()
	_update_status()


func _zoom(factor: float) -> void:
	grid.change_zoom(factor, grid.size / 2.0)


func _update_status() -> void:
	var message: String = grid.level.validation_message()
	play_button.disabled = not message.is_empty()
	play_button.tooltip_text = message
	var current := slots[slot]
	if grid.level.encode() != current.baseline:
		save_state.text = "Unsaved changes"
	else:
		save_state.text = "Saved locally" if current.saved else "Starter layout"
	undo_button.disabled = slots[slot].undo.is_empty()
	redo_button.disabled = slots[slot].redo.is_empty()
	status.text = message if not message.is_empty() else "Ready to playtest"
	status.add_theme_color_override("font_color", UI.GOLD if not message.is_empty() else UI.MINT)



func has_unsaved_edits() -> bool:
	for current in slots:
		if current.level.encode() != current.baseline:
			return true
	return false


func _save() -> void:
	var path := _path(slot)
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		status.text = "Couldn't write this level. Your draft is still open."
		return
	var data: Dictionary = grid.level.encode()
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(temporary, path) != OK:
		status.text = "Couldn't save this level. Your draft is still open."
		return
	slots[slot].baseline = data
	slots[slot].saved = true
	_update_status()


func _playtest() -> void:
	if grid.level.validation_message().is_empty():
		playtest.emit(Level.decode(grid.level.encode()))


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F5:
		_playtest()
	elif event.keycode == KEY_ESCAPE:
		back.emit()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_8 and not event.is_command_or_control_pressed():
		_select_brush(event.keycode - KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:
		return
	if not event.is_command_or_control_pressed():
		return
	if event.keycode == KEY_S:
		_save()
	elif get_viewport().gui_get_focus_owner() != title_field:
		if event.keycode == KEY_Z and not event.shift_pressed:
			_undo()
		elif event.keycode == KEY_Y or (event.keycode == KEY_Z and event.shift_pressed):
			_redo()
		else:
			return
	else:
		return
	get_viewport().set_input_as_handled()
