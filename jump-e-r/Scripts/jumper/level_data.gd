extends RefCounted

enum { EMPTY, GRASS, STONE, SPIKES, SPRING, COIN, START, EXIT }

const WIDTH := 40
const HEIGHT := 20
const TILE := 64
const SYMBOLS := ".#^!$oSE"
const TITLES := ["Cloudline", "Springworks", "Nightfall"]
const DESCRIPTIONS := [
	"Find your rhythm above the clouds.",
	"Chain spring launches across a broken skyline.",
	"Thread a narrow route through the spike fields.",
]

var title := "Untitled level"
var cells := PackedByteArray()


func _init() -> void:
	cells.resize(WIDTH * HEIGHT)


func contains(cell: Vector2i) -> bool:
	return Rect2i(0, 0, WIDTH, HEIGHT).has_point(cell)


func tile_at(cell: Vector2i) -> int:
	if not contains(cell):
		return EMPTY
	return cells[cell.y * WIDTH + cell.x]


func paint(cell: Vector2i, tile: int) -> void:
	if not contains(cell) or tile_at(cell) == tile:
		return
	if tile == START or tile == EXIT:
		var old_index := cells.find(tile)
		if old_index >= 0:
			cells[old_index] = EMPTY
	cells[cell.y * WIDTH + cell.x] = tile


func validation_message() -> String:
	if not cells.has(START):
		return "Place a spawn tile to playtest."
	if not cells.has(EXIT):
		return "Place an exit tile to playtest."
	return ""


func encode() -> Dictionary:
	var rows: Array[String] = []
	for y in HEIGHT:
		var row := ""
		for x in WIDTH:
			row += SYMBOLS[tile_at(Vector2i(x, y))]
		rows.append(row)
	return {"version": 1, "title": title, "rows": rows}


static func decode(data: Variant) -> RefCounted:
	if not data is Dictionary or data.get("version") != 1:
		return null
	var rows: Variant = data.get("rows")
	if not rows is Array or rows.size() != HEIGHT:
		return null
	var level := new()
	var saved_title: Variant = data.get("title")
	if saved_title is String and not saved_title.strip_edges().is_empty():
		level.title = saved_title.strip_edges().left(32)
	for y in HEIGHT:
		var row: Variant = rows[y]
		if not row is String or row.length() != WIDTH:
			return null
		for x in WIDTH:
			var tile := SYMBOLS.find(row[x])
			if tile < 0:
				return null
			level.cells[y * WIDTH + x] = tile
	if level.cells.count(START) > 1 or level.cells.count(EXIT) > 1:
		return null
	return level


static func starter() -> RefCounted:
	var level := new()
	level._ledge(1, 13, 15)
	level._ledge(16, 24, 14)
	level.paint(Vector2i(3, 14), START)
	level.paint(Vector2i(20, 12), COIN)
	level.paint(Vector2i(23, 13), EXIT)
	return level


static func campaign(index: int) -> RefCounted:
	var level := new()
	level.title = TITLES[index]
	match index:
		0:
			level._ledge(1, 9, 16)
			level._ledge(12, 22, 15)
			level._ledge(23, 30, 14)
			level._ledge(31, 38, 13)
			level._trinkets([Vector2i(7, 13), Vector2i(16, 12), Vector2i(26, 11), Vector2i(34, 10)])
			level.paint(Vector2i(3, 15), START)
			level.paint(Vector2i(37, 12), EXIT)
		1:
			level._ledge(1, 9, 17)
			level._ledge(13, 21, 13)
			level._ledge(25, 33, 9)
			level._ledge(34, 38, 8)
			level.paint(Vector2i(7, 16), SPRING)
			level.paint(Vector2i(19, 12), SPRING)
			level._trinkets([Vector2i(9, 12), Vector2i(16, 8), Vector2i(23, 5), Vector2i(28, 4)])
			level.paint(Vector2i(3, 16), START)
			level.paint(Vector2i(37, 7), EXIT)
		2:
			level._ledge(1, 11, 16)
			level._ledge(13, 20, 15)
			level._ledge(21, 28, 14)
			level._ledge(30, 38, 13)
			for cell in [Vector2i(7, 15), Vector2i(16, 14), Vector2i(25, 13), Vector2i(33, 12)]:
				level.paint(cell, SPIKES)
			level._trinkets([Vector2i(7, 13), Vector2i(16, 12), Vector2i(25, 11), Vector2i(33, 10)])
			level.paint(Vector2i(3, 15), START)
			level.paint(Vector2i(37, 12), EXIT)
	return level


func _ledge(first: int, last: int, y: int) -> void:
	for x in range(first, last + 1):
		paint(Vector2i(x, y), GRASS)
		if x > first and x < last:
			paint(Vector2i(x, y + 1), STONE)


func _trinkets(positions: Array) -> void:
	for cell in positions:
		paint(cell, COIN)
