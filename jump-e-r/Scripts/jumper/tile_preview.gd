extends Control

const Art := preload("res://Scripts/jumper/tile_art.gd")
var tile := 0


func _draw() -> void:
	Art.draw(self, Rect2(Vector2.ZERO, size), tile)
