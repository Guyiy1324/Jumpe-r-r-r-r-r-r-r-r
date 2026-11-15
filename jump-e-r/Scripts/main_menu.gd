extends Control

const UI := preload("res://Scripts/jumper/interface.gd")
const Level := preload("res://Scripts/jumper/level_data.gd")
const Scenery := preload("res://Scripts/jumper/scenery.gd")
const Workshop := preload("res://Scripts/jumper/workshop.gd")
const Run := preload("res://Scripts/jumper/run.gd")
const Preview := preload("res://Scripts/jumper/campaign_preview.gd")
const TAP := preload("res://Assets/brackeys_platformer_assets/sounds/tap.wav")

var screen: Control
var workshop: Control
var run: Node2D
var page := "menu"
var click := AudioStreamPlayer.new()
var quit_dialog: ConfirmationDialog


func _ready() -> void:
	theme = UI.theme()
	get_tree().auto_accept_quit = false
	click.bus = &"SFX"
	click.stream = TAP
	click.volume_db = -14.0
	add_child(click)
	_show_menu()


func _new_screen(destination: String, background := true) -> VBoxContainer:
	page = destination
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
	if is_instance_valid(workshop):
		workshop.hide()
	screen = Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if background:
		var backdrop := ColorRect.new()
		backdrop.color = UI.INK
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := UI.margins(screen, 36, 24)
	var stack := UI.vbox(18)
	frame.add_child(stack)
	return stack


func _nav(parent: VBoxContainer, can_go_back: bool) -> HBoxContainer:
	var row := UI.hbox(10)
	parent.add_child(row)
	if can_go_back:
		row.add_child(_action("‹   Main menu", _show_menu))
	else:
		var brand := UI.label("J  /  J", 13, UI.MINT, true)
		row.add_child(brand)
		row.add_child(UI.label("JUMPER JUMP", 11, UI.WHITE, true))
	row.add_child(UI.spacer())
	return row


func _action(copy: String, callback: Callable, primary := false, height := 42) -> Button:
	return UI.button(copy, func(): click.play(); callback.call(), primary, height)


func _show_menu() -> void:
	JumperState.soundtrack(false)
	var layout := _new_screen("menu")
	var nav := _nav(layout, false)
	nav.add_child(_action("Settings", _show_settings))
	nav.add_child(_action("Credits", _show_credits))
	var body := UI.hbox(24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var left := UI.vbox(13)
	left.custom_minimum_size.x = 382
	body.add_child(left)
	left.add_child(UI.spacer(true))
	left.add_child(UI.label("AUTO-BOUNCE PLATFORMER", 10, UI.MINT, true))
	var title := UI.label("JUMPER\nJUMP", 43, UI.WHITE, true)
	title.add_theme_constant_override("line_spacing", 8)
	left.add_child(title)
	var pitch := UI.label("Bounce across the skyline or build a level of your own.", 19, UI.MUTED)
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitch.custom_minimum_size.x = 330
	left.add_child(pitch)
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	left.add_child(gap)
	var play := _action("Play campaign   ›", _show_campaign, true, 53)
	left.add_child(play)
	left.add_child(_action("Level workshop   ›", _show_workshop, false, 53))
	left.add_child(UI.spacer(true))

	var art_panel := UI.panel(UI.PANEL, UI.LINE, 3)
	art_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(art_panel)
	var art := Scenery.new()
	art_panel.add_child(art)
	var plate := UI.panel(Color("#1c2540"), Color("#4e5782"), 9)
	art.add_child(plate)
	plate.position = Vector2(16, 16)
	plate.add_child(UI.label("CLOUDLINE", 10, UI.WHITE, true))

	var footer := UI.hbox(8)
	layout.add_child(footer)
	footer.add_child(UI.key_hint("A / D or arrows   Steer"))
	footer.add_child(UI.key_hint("Space   Wall jump"))
	footer.add_child(UI.spacer())
	footer.add_child(_action("Quit game", _quit, false, 34))
	play.grab_focus()


func _show_campaign() -> void:
	JumperState.soundtrack(false)
	var layout := _new_screen("campaign")
	_nav(layout, true)
	var headings := UI.vbox(6)
	layout.add_child(headings)
	headings.add_child(UI.label("CAMPAIGN", 11, UI.MINT, true))
	headings.add_child(UI.label("Choose a level", 38))
	headings.add_child(UI.label("Reach the exit. Collect coins along the way.", 18, UI.MUTED))
	var cards := UI.hbox(14)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(cards)
	var start: Button
	for i in Level.TITLES.size():
		var level := Level.campaign(i)
		var card := UI.panel(UI.PANEL, UI.LINE, 14)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(card)
		var contents := UI.vbox(9)
		card.add_child(contents)
		var preview := Preview.new()
		preview.level = level
		preview.variant = i
		preview.custom_minimum_size.y = 148
		preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
		contents.add_child(preview)
		contents.add_child(UI.label("LEVEL %02d" % (i + 1), 10, UI.MINT, true))
		contents.add_child(UI.label(level.title, 29))
		var detail := UI.label(Level.DESCRIPTIONS[i], 16, UI.MUTED)
		detail.custom_minimum_size.y = 48
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contents.add_child(detail)
		var prior: Dictionary = JumperState.records.get(i, {})
		var record := "No clear yet"
		if not prior.is_empty():
			record = "Best %s  •  Coins %d/4" % [JumperState.format_time(prior.time), prior.coins]
		contents.add_child(UI.label(record, 15, UI.GOLD))
		var play := _action("Play " + level.title, _start.bind(level, i), i == 0)
		contents.add_child(play)
		if i == 0:
			start = play
	start.grab_focus()


func _show_workshop() -> void:
	page = "workshop"
	JumperState.soundtrack(false)
	if is_instance_valid(screen):
		remove_child(screen)
		screen.queue_free()
		screen = null
	if not is_instance_valid(workshop):
		workshop = Workshop.new()
		workshop.back.connect(_show_menu)
		workshop.playtest.connect(_start.bind(-1))
		add_child(workshop)
		workshop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workshop.show()


func _start(level: RefCounted, index: int) -> void:
	page = "run"
	if is_instance_valid(screen):
		screen.hide()
	if is_instance_valid(workshop):
		workshop.hide()
	JumperState.soundtrack(true)
	run = Run.new()
	run.level = level
	run.campaign_index = index
	run.leave.connect(_end_run.bind(index), CONNECT_DEFERRED)
	run.replay.connect(_restart.bind(level, index), CONNECT_DEFERRED)
	run.next_level.connect(_next.bind(index), CONNECT_DEFERRED)
	add_child(run)


func _remove_run() -> void:
	get_tree().paused = false
	if is_instance_valid(run):
		remove_child(run)
		run.queue_free()
		run = null


func _end_run(index: int) -> void:
	_remove_run()
	if index < 0:
		_show_workshop()
	else:
		_show_campaign()


func _restart(level: RefCounted, index: int) -> void:
	_remove_run()
	_start(level, index)


func _next(index: int) -> void:
	_remove_run()
	_start(Level.campaign(index + 1), index + 1)


func _utility_page(destination: String, title: String) -> VBoxContainer:
	var layout := _new_screen(destination)
	_nav(layout, true)
	var centered := CenterContainer.new()
	centered.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(centered)
	var card := UI.panel(UI.PANEL, UI.LINE, 28)
	card.custom_minimum_size.x = 540
	centered.add_child(card)
	var content := UI.vbox(16)
	card.add_child(content)
	content.add_child(UI.label(title, 36))
	return content


func _show_settings() -> void:
	var content := _utility_page("settings", "Settings")
	for bus in ["Music", "SFX"]:
		var row := UI.hbox(15)
		content.add_child(row)
		var caption := UI.label("Music" if bus == "Music" else "Sound effects")
		caption.custom_minimum_size.x = 142
		row.add_child(caption)
		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = JumperState.volume(bus)
		row.add_child(slider)
		var value := UI.label("%d%%" % int(round(slider.value * 100.0)), 15, UI.MUTED)
		value.custom_minimum_size.x = 45
		row.add_child(value)
		slider.value_changed.connect(func(amount: float):
			JumperState.set_volume(bus, amount)
			value.text = "%d%%" % int(round(amount * 100.0))
		)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.set_pressed_no_signal(JumperState.fullscreen)
	fullscreen.toggled.connect(JumperState.set_fullscreen)
	content.add_child(fullscreen)
	content.add_child(UI.label("Settings are saved on this device.", 14, UI.MUTED))


func _show_credits() -> void:
	var content := _utility_page("credits", "Credits")
	content.add_child(UI.label("Hezikial, Johny, and Jery group", 16, UI.MUTED))
	content.add_child(UI.label("Programming   Hezikial, Johny", 17))
	content.add_child(UI.label("Sound design   Jery", 17))
	content.add_child(UI.label("Art and visual design   Jery, Godoe, le Goog", 17))
	content.add_child(UI.label("Debugging   Jerry", 17))
	content.add_child(UI.label("Platformer assets", 20, UI.MINT))
	for credit in [
		"Sprites and tiles   analogStudios_, RottingPixels",
		"Sound and music   Asbjørn Thirslund, Sofia Thirslund",
		"Pixel Operator font   Jayvee Enaguas",
	]:
		content.add_child(UI.label(credit, 15, UI.MUTED))
	var repository := LinkButton.new()
	repository.text = "View the project on GitHub"
	repository.uri = "https://github.com/Guyiy1324/Jumpe-r-r-r-r-r-r-r-r"
	repository.add_theme_color_override("font_color", UI.MINT)
	content.add_child(repository)



func _quit() -> void:
	if not is_instance_valid(workshop) or not workshop.has_unsaved_edits():
		get_tree().quit()
		return
	if not is_instance_valid(quit_dialog):
		quit_dialog = ConfirmationDialog.new()
		quit_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		quit_dialog.title = "Quit Jumper Jump?"
		quit_dialog.dialog_text = "There are unsaved changes in the workshop."
		quit_dialog.ok_button_text = "Quit without saving"
		quit_dialog.confirmed.connect(get_tree().quit)
		add_child(quit_dialog)
	quit_dialog.popup_centered(Vector2i(420, 145))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()


func _unhandled_input(event: InputEvent) -> void:
	if page in ["campaign", "settings", "credits"] and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_show_menu()
