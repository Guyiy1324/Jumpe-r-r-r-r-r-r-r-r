extends RefCounted

const Level = preload("res://Scripts/jumper/level_data.gd")
const ATLAS = preload("res://Assets/brackeys_platformer_assets/sprites/world_tileset.png")
const COIN_ART = preload("res://Assets/brackeys_platformer_assets/sprites/coin.png")
const BALL = preload("res://Assets/player_ball.svg")
const VINE = preload("res://Assets/Vines'.png")
const SKY = preload("res://Assets/game_background.jpg")

const POOL := Color("#64f0cb")
const GOLD := Color("#ffd18a")
const CORAL := Color("#ff869d")


static func draw(canvas: CanvasItem, box: Rect2, tile: int, time := 0.0) -> void:
	var p := box.position
	var s := box.size.x
	var center := box.get_center()
	match tile:
		Level.GRASS:
			canvas.draw_texture_rect_region(ATLAS, box, Rect2(0, 0, 16, 16))
			canvas.draw_rect(Rect2(p, Vector2(s, s * 0.08)), Color("#93db92"))
		Level.STONE:
			canvas.draw_texture_rect_region(ATLAS, box, Rect2(96, 16, 16, 16), Color("#a4a7c9"))
		Level.SPIKES:
			canvas.draw_rect(Rect2(p + Vector2(0, s * 0.85), Vector2(s, s * 0.15)), Color("#582943"))
			for i in 3:
				var base := p + Vector2(s * i / 3.0, s * 0.85)
				var tip := base + Vector2(s / 6.0, -s * 0.45)
				var edge := base + Vector2(s / 3.0, 0)
				canvas.draw_colored_polygon(PackedVector2Array([base, tip, edge]), CORAL)
				canvas.draw_line(tip, edge, Color("#993c63"), maxf(1.0, s * 0.035))
		Level.SPRING:
			canvas.draw_rect(Rect2(p + Vector2(s * 0.08, s * 0.69), Vector2(s * 0.84, s * 0.29)), Color("#163f45"))
			canvas.draw_rect(Rect2(p + Vector2(s * 0.08, s * 0.69), Vector2(s * 0.84, s * 0.11)), POOL)
			canvas.draw_texture_rect(VINE, Rect2(p + Vector2(s * 0.05, s * 0.16), Vector2(s * 0.9, s * 0.54)), false)
		Level.COIN:
			var bob := sin(time * 4.0 + p.x) * s * 0.07
			var coin_center := center + Vector2(0, bob)
			canvas.draw_circle(coin_center, s * 0.28, Color(1, 0.69, 0.26, 0.13))
			canvas.draw_texture_rect_region(COIN_ART, Rect2(coin_center - Vector2.ONE * s * 0.49, Vector2.ONE * s * 0.98), Rect2(0, 0, 16, 16))
		Level.START:
			canvas.draw_circle(center, s * 0.46, Color(0.42, 0.86, 1, 0.14))
			canvas.draw_texture_rect(BALL, Rect2(center - Vector2.ONE * s * 0.32, Vector2.ONE * s * 0.64), false)
		Level.EXIT:
			var portal := Rect2(p + Vector2(s * 0.17, s * 0.08), Vector2(s * 0.66, s * 0.92))
			canvas.draw_rect(portal.grow(s * 0.07), Color(0.37, 1, 0.78, 0.15))
			canvas.draw_rect(portal, Color("#1d645e"))
			canvas.draw_rect(portal.grow(-s * 0.10), Color("#132c45"))
			canvas.draw_rect(portal, POOL, false, maxf(1.0, s * 0.055))
			var radius := s * (0.11 + 0.025 * sin(time * 4.0))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)]), POOL)
		Level.EMPTY:
			canvas.draw_line(p + Vector2.ONE * s * 0.25, p + Vector2.ONE * s * 0.75, Color("#8196b6"), maxf(1.0, s * 0.05))
			canvas.draw_line(p + Vector2(s * 0.75, s * 0.25), p + Vector2(s * 0.25, s * 0.75), Color("#8196b6"), maxf(1.0, s * 0.05))
