extends Control

signal stroke_started
signal tile_painted(cell: Vector2i, tile: int)

const Level := preload("res://Scripts/jumper/level_data.gd")
const Art := preload("res://Scripts/jumper/tile_art.gd")
const UI := preload("res://Scripts/jumper/interface.gd")

var level: RefCounted
var brush := Level.GRASS
var show_grid := true
var zoom := 1.0
var pan := Vector2.ZERO
var hover := Vector2i(-1, -1)
var previous := Vector2i(-1, -1)
var painting := 0
var panning := false


func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	resized.connect(_layout_changed)
	mouse_exited.connect(_clear_hover)


func _layout_changed() -> void:
	_clamp_pan()
	queue_redraw()


func _clear_hover() -> void:
	hover = Vector2i(-1, -1)
	queue_redraw()


func _tile_size() -> float:
	return floorf(minf((size.x - 24) / Level.WIDTH, (size.y - 24) / Level.HEIGHT)) * zoom


func _origin() -> Vector2:
	return (size - Vector2(Level.WIDTH, Level.HEIGHT) * _tile_size()) / 2.0 + pan


func _clamp_pan() -> void:
	var overflow := (Vector2(Level.WIDTH, Level.HEIGHT) * _tile_size() - size + Vector2.ONE * 24) / 2.0
	overflow = overflow.max(Vector2.ZERO)
	pan = pan.clamp(-overflow, overflow)


func change_zoom(factor: float, around: Vector2) -> void:
	var anchor := (around - _origin()) / maxf(_tile_size(), 1.0)
	zoom = clampf(zoom * factor, 1.0, 3.0)
	var footprint := Vector2(Level.WIDTH, Level.HEIGHT) * _tile_size()
	pan = around - (size - footprint) / 2.0 - anchor * _tile_size()
	_clamp_pan()
	queue_redraw()


func reset_view() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if level == null or _tile_size() < 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#101524"))
	var tile_size := _tile_size()
	var origin := _origin()
	var footprint := Vector2(Level.WIDTH, Level.HEIGHT) * tile_size
	draw_texture_rect(Art.SKY, Rect2(origin, footprint), false, Color("#474473"))
	draw_rect(Rect2(origin, footprint), Color(0.03, 0.05, 0.11, 0.3))
	if show_grid:
		for x in range(Level.WIDTH + 1):
			var at := origin + Vector2(x * tile_size, 0)
			draw_line(at, at + Vector2(0, footprint.y), Color(0.65, 0.72, 1.0, 0.17 if x % 5 == 0 else 0.08))
		for y in range(Level.HEIGHT + 1):
			var at := origin + Vector2(0, y * tile_size)
			draw_line(at, at + Vector2(footprint.x, 0), Color(0.65, 0.72, 1.0, 0.17 if y % 5 == 0 else 0.08))
	for y in Level.HEIGHT:
		for x in Level.WIDTH:
			var tile: int = level.tile_at(Vector2i(x, y))
			if tile != Level.EMPTY:
				Art.draw(self, Rect2(origin + Vector2(x, y) * tile_size, Vector2.ONE * tile_size), tile)
	draw_rect(Rect2(origin, footprint), UI.LINE, false)
	if level.contains(hover):
		var region := Rect2(origin + Vector2(hover) * tile_size, Vector2.ONE * tile_size)
		draw_rect(region, Color(0.47, 0.94, 0.8, 0.19))
		draw_rect(region, UI.MINT, false, 2.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					change_zoom(1.2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2, event.position)
			MOUSE_BUTTON_MIDDLE:
				panning = event.pressed
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if event.pressed and painting == 0:
					grab_focus()
					painting = event.button_index
					stroke_started.emit()
					_paint_at(event.position)
				elif not event.pressed and event.button_index == painting:
					painting = 0
					previous = Vector2i(-1, -1)
		accept_event()
	elif event is InputEventMouseMotion:
		if panning:
			pan += event.relative
			_clamp_pan()
		hover = _cell_at(event.position)
		if painting:
			_paint_at(event.position)
		queue_redraw()


func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(((point - _origin()) / maxf(_tile_size(), 1.0)).floor())


func _paint_at(point: Vector2) -> void:
	var cell := _cell_at(point)
	if not level.contains(cell):
		previous = Vector2i(-1, -1)
		return
	var tile := brush if painting == MOUSE_BUTTON_LEFT else Level.EMPTY
	if level.contains(previous):
		var distance := maxi(absi(cell.x - previous.x), absi(cell.y - previous.y))
		for i in range(1, distance + 1):
			var step := Vector2(previous).lerp(Vector2(cell), float(i) / distance)
			tile_painted.emit(Vector2i(step.round()), tile)
	else:
		tile_painted.emit(cell, tile)
	previous = cell
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		painting = 0
		panning = false
		previous = Vector2i(-1, -1)
