extends Node2D

signal leave
signal next_level
signal replay

const Level := preload("res://Scripts/jumper/level_data.gd")
const Art := preload("res://Scripts/jumper/tile_art.gd")
const UI := preload("res://Scripts/jumper/interface.gd")
const Scenery := preload("res://Scripts/jumper/scenery.gd")
const RunInput := preload("res://Scripts/jumper/run_input.gd")
const PLAYER := preload("res://Scenes/player.tscn")
const SPRING_SOUND := preload("res://Assets/Audio Files/spring.wav")
const COIN_SOUND := preload("res://Assets/brackeys_platformer_assets/sounds/coin.wav")
const CLEAR_SOUND := preload("res://Assets/brackeys_platformer_assets/sounds/power_up.wav")

var level: RefCounted
var campaign_index := -1
var ball: CharacterBody2D
var spawn: Vector2
var elapsed := 0.0
var falls := 0
var coins := 0
var total_coins := 0
var collected: Dictionary = {}
var scenery: Control
var hud: Control
var modal: Control
var clock: Label
var score: Label
var fall_counter: Label
var sound: AudioStreamPlayer
var finished := false
var intro: PanelContainer
var trail := PackedVector2Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var background := CanvasLayer.new()
	background.layer = -1
	add_child(background)
	scenery = Scenery.new()
	scenery.hero = false
	if campaign_index >= 0:
		scenery.sky_tint = [Color("#7474ac"), Color("#8978a7"), Color("#586b9d")][campaign_index]
	background.add_child(scenery)
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_world()
	_build_hud()


func _process(delta: float) -> void:
	elapsed += delta
	clock.text = JumperState.format_time(elapsed)
	if elapsed >= 7.0 and intro.visible:
		intro.hide()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var p := ball.global_position
	if not ball.is_dead:
		if trail.size() == 7:
			trail.remove_at(0)
		trail.append(p)
	if p.y > Level.HEIGHT * Level.TILE + 90 or p.x < -180 or p.x > Level.WIDTH * Level.TILE + 180:
		_fall(ball)


func _draw() -> void:
	if level == null:
		return
	for y in Level.HEIGHT:
		for x in Level.WIDTH:
			var cell := Vector2i(x, y)
			var tile: int = level.tile_at(cell)
			if tile != Level.EMPTY and tile != Level.START and not collected.has(cell):
				Art.draw(self, Rect2(Vector2(cell * Level.TILE), Vector2.ONE * Level.TILE), tile, elapsed)
	var intensity := minf(ball.velocity.length() / 540.0, 1.0)
	for i in trail.size():
		var weight := float(i + 1) / trail.size()
		draw_circle(trail[i], lerpf(4.0, 20.0, weight), Color(0.48, 0.89, 1.0, weight * intensity * 0.12), true, -1.0, true)


func _build_world() -> void:
	var terrain := StaticBody2D.new()
	add_child(terrain)
	for y in Level.HEIGHT:
		var x := 0
		while x < Level.WIDTH:
			var cell := Vector2i(x, y)
			var tile: int = level.tile_at(cell)
			var center := (Vector2(cell) + Vector2(0.5, 0.5)) * Level.TILE
			match tile:
				Level.GRASS, Level.STONE:
					var end := x + 1
					while end < Level.WIDTH and level.tile_at(Vector2i(end, y)) in [Level.GRASS, Level.STONE]:
						end += 1
					var width := float((end - x) * Level.TILE)
					_shape(terrain, Vector2(x * Level.TILE + width / 2.0, center.y), Vector2(width, Level.TILE))
					x = end
					continue
				Level.START:
					spawn = center
				Level.EXIT:
					_trigger(center + Vector2(0, 4), Vector2(34, 56), _complete)
				Level.COIN:
					total_coins += 1
					_trigger(center, Vector2(34, 34), _collect.bind(cell))
				Level.SPIKES:
					_trigger(center + Vector2(0, 13), Vector2(53, 26), _fall)
				Level.SPRING:
					_trigger(center + Vector2(0, 18), Vector2(52, 15), _spring)
			x += 1
	var player := PLAYER.instantiate()
	ball = player.get_node("Area2D/CharacterBody2D")
	var hitbox: CollisionShape2D = ball.get_node("CollisionShape2D")
	hitbox.scale = Vector2.ONE * 3.2
	ball.floor_max_angle = deg_to_rad(44.0)
	ball.get_node("AudioStreamPlayer").volume_db = -6.0
	var camera: Camera2D = ball.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 0.86
	camera.offset = Vector2(100, -75)
	camera.limit_left = -110
	camera.limit_top = -60
	camera.limit_right = (Level.WIDTH * Level.TILE) + 105
	camera.limit_bottom = (Level.HEIGHT * Level.TILE) + 12
	player.position = spawn
	add_child(player)
	camera.reset_smoothing()
	sound = AudioStreamPlayer.new()
	sound.bus = &"SFX"
	sound.volume_db = -7.0
	add_child(sound)


func _shape(parent: CollisionObject2D, center: Vector2, dimensions: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = center
	parent.add_child(collider)


func _trigger(center: Vector2, dimensions: Vector2, action: Callable) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	_shape(area, center, dimensions)
	area.body_entered.connect(action)
	add_child(area)


func _fall(body: Node2D) -> void:
	if body != ball or ball.is_dead or finished:
		return
	trail.clear()
	falls += 1
	fall_counter.text = "Falls  %d" % falls
	ball.die(spawn)


func _spring(body: Node2D) -> void:
	if body == ball and not ball.is_dead and ball.velocity.y >= 0:
		ball.bounce(1020.0)
		_play_sound(SPRING_SOUND)


func _collect(body: Node2D, cell: Vector2i) -> void:
	if body != ball or ball.is_dead or finished or collected.has(cell):
		return
	collected[cell] = true
	coins += 1
	score.text = "Coins  %d / %d" % [coins, total_coins]
	_play_sound(COIN_SOUND)


func _play_sound(stream: AudioStream) -> void:
	sound.stream = stream
	sound.play()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = UI.theme()
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := UI.margins(hud, 24, 20)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout := UI.vbox(8)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(layout)
	var top := UI.hbox(10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(top)
	var nameplate := UI.panel(UI.INK, UI.LINE, 12)
	var names := UI.vbox(5)
	nameplate.add_child(names)
	var mode := "WORKSHOP PLAYTEST" if campaign_index < 0 else "CAMPAIGN  /  %02d" % (campaign_index + 1)
	names.add_child(UI.label(mode, 10, UI.MINT, true))
	names.add_child(UI.label(level.title, 22))
	top.add_child(nameplate)
	top.add_child(UI.spacer())
	var stats := UI.panel(UI.INK, UI.LINE, 12)
	var stat_row := UI.hbox(20)
	stats.add_child(stat_row)
	clock = UI.label("00:00.0", 15, UI.WHITE, true)
	score = UI.label("Coins  0 / %d" % total_coins, 16, UI.GOLD)
	fall_counter = UI.label("Falls  0", 16, UI.MUTED)
	fall_counter.custom_minimum_size.x = 76
	for stat in [clock, score, fall_counter]:
		stat_row.add_child(stat)
	top.add_child(stats)
	var pause := UI.button("Pause", _pause)
	pause.custom_minimum_size.x = 94
	top.add_child(pause)
	layout.add_child(UI.spacer(true))
	intro = UI.panel(UI.INK, UI.LINE, 10)
	intro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tip := "A / D or arrows to steer  •  Space by a wall to rebound  •  Esc to pause"
	match campaign_index:
		0:
			tip = "You bounce automatically. Steer with A / D or the arrow keys."
		1:
			tip = "Land on the green spring pads to reach higher platforms."
		2:
			tip = "Time your bounces over the spikes. Ease off near the exit."
	intro.add_child(UI.label(tip, 15, UI.MUTED))
	layout.add_child(intro)
	var input := RunInput.new()
	hud.add_child(input)
	input.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Unhandled input still reaches this layer while the world is paused.
	input.pause_requested.connect(_toggle_pause)


func _toggle_pause() -> void:
	if finished:
		return
	if get_tree().paused:
		_resume()
	else:
		_pause()


func _pause() -> void:
	if finished or get_tree().paused:
		return
	get_tree().paused = true
	var content := _overlay("RUN PAUSED", "Take a breather", "Your run will resume from here.")
	var resume := UI.button("Resume", _resume, true)
	content.add_child(resume)
	content.add_child(UI.button("Restart run", _replay))
	content.add_child(UI.button("Back to workshop" if campaign_index < 0 else "Back to campaign", _leave))
	resume.grab_focus()


func _overlay(kicker: String, heading: String, detail: String) -> VBoxContainer:
	modal = ColorRect.new()
	modal.color = Color(0.036, 0.052, 0.101, 0.82)
	hud.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var alignment := CenterContainer.new()
	modal.add_child(alignment)
	alignment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := UI.panel(UI.PANEL, UI.LINE, 25)
	card.custom_minimum_size.x = 430
	alignment.add_child(card)
	var content := UI.vbox(12)
	card.add_child(content)
	content.add_child(UI.label(kicker, 11, UI.MINT, true))
	content.add_child(UI.label(heading, 31))
	content.add_child(UI.label(detail, 16, UI.MUTED))
	return content


func _resume() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal = null
	get_tree().paused = false


func _leave() -> void:
	_resume()
	leave.emit()


func _replay() -> void:
	_resume()
	replay.emit()


func _advance() -> void:
	_resume()
	next_level.emit()


func _complete(body: Node2D) -> void:
	if body != ball or ball.is_dead or finished:
		return
	finished = true
	var best := campaign_index >= 0 and JumperState.record(campaign_index, elapsed, coins)
	_play_sound(CLEAR_SOUND)
	sound.process_mode = Node.PROCESS_MODE_ALWAYS
	# Area signals can fire while physics queries are being flushed.
	_show_results.call_deferred(best)


func _show_results(best: bool) -> void:
	get_tree().paused = true
	var heading := "Playtest complete" if campaign_index < 0 else "Level cleared"
	var kicker := "NEW BEST TIME" if best else "RUN COMPLETE"
	var detail := "%s   •   %d/%d coins   •   %d falls" % [JumperState.format_time(elapsed), coins, total_coins, falls]
	var content := _overlay(kicker, heading, detail)
	var next: Button
	if campaign_index >= 0 and campaign_index < Level.TITLES.size() - 1:
		next = UI.button("Next level", _advance, true)
	else:
		next = UI.button("Back to workshop" if campaign_index < 0 else "Back to campaign", _leave, true)
	content.add_child(next)
	content.add_child(UI.button("Play again", _replay))
	if campaign_index >= 0 and campaign_index < Level.TITLES.size() - 1:
		content.add_child(UI.button("Back to campaign", _leave))
	next.grab_focus()
