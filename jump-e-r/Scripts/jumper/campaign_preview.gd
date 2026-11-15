extends Control

const Art := preload("res://Scripts/jumper/tile_art.gd")
const Level := preload("res://Scripts/jumper/level_data.gd")
const UI := preload("res://Scripts/jumper/interface.gd")

var level: RefCounted
var variant := 0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.INK)
	var tint := [Color("#8889c3"), Color("#827caf"), Color("#57669b")]
	draw_texture_rect(Art.SKY, Rect2(Vector2.ZERO, size), false, tint[variant])
	var tile_size := floorf(minf((size.x - 16.0) / Level.WIDTH, (size.y - 14.0) / 14.0))
	var origin := Vector2((size.x - tile_size * Level.WIDTH) / 2.0, size.y - 12.0 - tile_size * Level.HEIGHT)
	for y in Level.HEIGHT:
		for x in Level.WIDTH:
			var tile: int = level.tile_at(Vector2i(x, y))
			if tile != Level.EMPTY:
				Art.draw(self, Rect2(origin + Vector2(x, y) * tile_size, Vector2.ONE * tile_size), tile)
	draw_rect(Rect2(Vector2.ZERO, size), UI.LINE, false)
