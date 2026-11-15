extends Node2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@export var bounce_velocity: float = 1200.0
@export var movement_velocity: float = 1000

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.velocity.y = -bounce_velocity
		body.velocity.x
		#audio_stream_player.play()
