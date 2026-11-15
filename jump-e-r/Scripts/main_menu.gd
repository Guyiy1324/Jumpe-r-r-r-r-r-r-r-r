extends Control


const BACKGROUNDS: Array[Texture2D] = [
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 161914.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 161934.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 162002.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 162018.png"),
	preload("res://Assets/Backgrounds/icon.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 170728.png"),
	preload("res://Assets/Backgrounds/Screenshot 2026-11-14 172657.png")
]


func _ready() -> void:
	$Background.texture = BACKGROUNDS.pick_random()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_&_credits.tscn")
