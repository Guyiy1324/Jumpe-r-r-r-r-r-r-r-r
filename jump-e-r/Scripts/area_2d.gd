extends Area2D

@export var spawn_point: Marker2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		var respawn_position := spawn_point.global_position if spawn_point else Vector2.ZERO
		body.die(respawn_position)
