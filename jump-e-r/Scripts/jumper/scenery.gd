extends Control

const Art := preload("res://Scripts/jumper/tile_art.gd")
const Level := preload("res://Scripts/jumper/level_data.gd")
const UI := preload("res://Scripts/jumper/interface.gd")

var elapsed := 0.0
var hero := true
var sky_tint := Color("#7474ac")
var camera_origin := Vector2.INF
var shift := Vector2.ZERO

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if hero:
		elapsed += delta
		queue_redraw()
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var center := camera.get_screen_center_position()
	if camera_origin == Vector2.INF:
		camera_origin = center
	var drift := ((camera_origin - center) * 0.040).limit_length(66.0)
	if not shift.is_equal_approx(drift):
		shift = drift
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.INK)
	var overscan := 0.0 if hero else 144.0
	var sky_size := Art.SKY.get_size() * maxf((size.x + overscan) / Art.SKY.get_width(), (size.y + overscan) / Art.SKY.get_height())
	var tint := Color("#8b87cc") if hero else sky_tint
	draw_texture_rect(Art.SKY, Rect2((size - sky_size) / 2.0 + shift, sky_size), false, tint)
	if not hero:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.049, 0.102, 0.24))
		return
	var moon := size * Vector2(0.72, 0.29)
	draw_circle(moon, 68, Color(0.56, 0.62, 1.0, 0.09), true, -1.0, true)
	draw_circle(moon, 53, Color("#c4caf7"), true, -1.0, true)
	draw_circle(moon + Vector2(12, -9), 42, Color("#a3a9e0"), true, -1.0, true)
	for i in 27:
		var point := Vector2(fposmod(i * 119.6, size.x), fposmod(i * 71.5, size.y * 0.76))
		var alpha := 0.22 + 0.21 * sin(elapsed * 2.0 + i)
		draw_rect(Rect2(point, Vector2.ONE * (2 + i % 2)), Color(0.73, 0.82, 1.0, alpha))
	var tile := floorf(minf(size.x / 15.0, size.y / 11.0))
	var origin := Vector2((size.x - tile * 15.0) / 2.0, size.y * 0.82)
	_draw_ledge(origin, tile, 0, 4, 0)
	_draw_ledge(origin, tile, 6, 9, -2)
	_draw_ledge(origin, tile, 11, 14, -4)
	for point in [Vector2(4.4, -2.3), Vector2(6.8, -3.7), Vector2(9.5, -4.9)]:
		Art.draw(self, Rect2(origin + point * tile, Vector2.ONE * tile), Level.COIN, elapsed)
	Art.draw(self, Rect2(origin + Vector2(13, -5) * tile, Vector2.ONE * tile), Level.EXIT, elapsed)
	var bounce := sin(elapsed * 2.4)
	var ball := origin + Vector2(4.8 + bounce * 1.45, -3.2 - sin(elapsed * 2.4 + 0.4) * 0.58) * tile
	for i in range(4, 0, -1):
		draw_circle(ball - Vector2(i * 8, -i * 6), tile * (0.22 - i * 0.026), Color(0.44, 0.92, 1.0, 0.14), true, -1.0, true)
	Art.draw(self, Rect2(ball - Vector2.ONE * tile * 0.70, Vector2.ONE * tile * 1.40), Level.START)


func _draw_ledge(origin: Vector2, tile: float, first: int, last: int, row: int) -> void:
	for x in range(first, last + 1):
		var pos := origin + Vector2(x, row) * tile
		Art.draw(self, Rect2(pos, Vector2.ONE * tile), Level.GRASS)
		if x > first and x < last:
			Art.draw(self, Rect2(pos + Vector2(0, tile), Vector2.ONE * tile), Level.STONE)
