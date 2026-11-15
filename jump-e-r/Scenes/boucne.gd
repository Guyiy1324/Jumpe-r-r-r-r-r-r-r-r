extends Node2D

<<<<<<< Updated upstream
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
=======
@onready var audio_stream_player: AudioStreamPlayer = $Area2D/AudioStreamPlayer

>>>>>>> Stashed changes
@export var bounce_velocity: float = 1200.0

func _ready() -> void:
	audio_stream_player.stream = preload("res://Assets/Audio Files/spring.wav")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
<<<<<<< Updated upstream
		body.velocity.y = -bounce_velocity

=======
		if body.has_method("bounce"):
			body.bounce(bounce_velocity)
		else:
			body.velocity.y = -bounce_velocity
		body.velocity.x
		#audio_stream_player.play()
>>>>>>> Stashed changes
