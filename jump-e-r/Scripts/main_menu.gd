extends Control

const ROBLOX_GAME_URI: String = "roblox://placeId=109983668079237"
const ROBLOX_GAME_URL: String = "https://www.roblox.com/games/109983668079237/Steal-a-Brainrot"

const BACKGROUNDS: Array[Texture2D] = [
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 161914.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 161934.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 162002.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 162018.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 103140.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 172657.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 083537.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 102102.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 102121.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 102144.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-15 103024.png"),
	preload("res://Assets/Backgrounds/icon.png")
]


func _ready() -> void:
	$Background.texture = BACKGROUNDS.pick_random()


func _on_start_pressed() -> void:
	if randi_range(0, 1) == 0:
		get_tree().change_scene_to_file("res://Scenes/map.tscn")
	else:
		var error: Error = OS.shell_open(ROBLOX_GAME_URI)
		if error != OK:
			OS.shell_open(ROBLOX_GAME_URL)


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_&_credits.tscn")
