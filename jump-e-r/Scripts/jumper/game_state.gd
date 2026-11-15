extends Node

const PROFILE := "user://jumper_profile.cfg"
const MENU_MUSIC := preload("res://Assets/brackeys_platformer_assets/music/time_for_adventure.mp3")
const GAME_MUSIC := preload("res://Assets/Audio Files/Project Rusher - SURR3AL (Noteblock Cover).mp3")

var profile := ConfigFile.new()
var music := AudioStreamPlayer.new()
var records: Dictionary = {}
var fullscreen := false
var _current_track: AudioStreamMP3


func _ready() -> void:
	profile.load(PROFILE)
	var saved_records: Variant = profile.get_value("campaign", "records", {})
	if saved_records is Dictionary:
		records = saved_records
	if DisplayServer.get_name() != "headless":
		get_window().min_size = Vector2i(960, 540)
	for bus in ["Music", "SFX"]:
		set_volume(bus, float(profile.get_value("settings", bus, 0.65)), false)
	set_fullscreen(profile.get_value("settings", "fullscreen", false) == true, false)
	music.bus = &"Music"
	music.volume_db = -12.0
	add_child(music)


func soundtrack(in_game: bool) -> void:
	var track := GAME_MUSIC if in_game else MENU_MUSIC
	if _current_track == track:
		return
	_current_track = track
	var loop := track.duplicate() as AudioStreamMP3
	loop.loop = true
	music.stream = loop
	music.play()


func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()


func volume(bus: String) -> float:
	return float(profile.get_value("settings", bus, 0.65))


func set_volume(bus: String, value: float, save := true) -> void:
	value = clampf(value, 0.0, 1.0)
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_mute(index, is_zero_approx(value))
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))
	profile.set_value("settings", bus, value)
	if save:
		profile.save(PROFILE)


func set_fullscreen(enabled: bool, save := true) -> void:
	fullscreen = enabled
	if DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
	profile.set_value("settings", "fullscreen", enabled)
	if save:
		profile.save(PROFILE)


func record(index: int, elapsed: float, coins: int) -> bool:
	var prior: Dictionary = records.get(index, {})
	var fastest: bool = elapsed < float(prior.get("time", INF))
	records[index] = {"time": elapsed if fastest else prior["time"], "coins": maxi(coins, int(prior.get("coins", 0)))}
	profile.set_value("campaign", "records", records)
	profile.save(PROFILE)
	return fastest


func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d.%01d" % [whole / 60, whole % 60, int(seconds * 10) % 10]
