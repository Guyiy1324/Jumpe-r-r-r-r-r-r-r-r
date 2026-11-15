extends TextureRect

const OVERSCAN: float = 1.3
const PARALLAX_STRENGTH: float = 0.025

var camera_origin: Vector2
var has_camera_origin: bool = false


func _process(_delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	size = viewport_size * OVERSCAN
	var margin := (size - viewport_size) / 2.0
	var offset := Vector2.ZERO
	var camera := get_viewport().get_camera_2d()
	if camera:
		var camera_position := camera.get_screen_center_position()
		if not has_camera_origin:
			camera_origin = camera_position
			has_camera_origin = true
		offset = -(camera_position - camera_origin) * PARALLAX_STRENGTH
		offset = offset.clamp(-margin, margin)
	position = -margin + offset
