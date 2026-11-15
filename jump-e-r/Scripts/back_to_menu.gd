extends TextureButton

var hover_tween: Tween


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))


func _set_hovered(hovered: bool) -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2, 1.0) if hovered else Color.WHITE, 0.15)


func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
