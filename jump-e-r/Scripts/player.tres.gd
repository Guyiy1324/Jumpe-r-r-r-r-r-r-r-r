extends CharacterBody2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

const SPEED: float = 500.0
const JUMP_VELOCITY: float = -600.0
const WALL_REBOUND_SPEED: float = 700.0

const WALL_REBOUND_DECELERATION: float = 1500

var wall_rebounding: bool = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_on_floor():
		wall_rebounding = false
		velocity.y = JUMP_VELOCITY
		velocity.x -= 10
		audio_stream_player.play()
	var direction: float = Input.get_axis("ui_left", "ui_right")
	if wall_rebounding:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			WALL_REBOUND_DECELERATION * log(delta)
		)
		if is_zero_approx(velocity.x):
			velocity.x = 0.0
			wall_rebounding = false
	else:
		if direction != 0.0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				SPEED * delta
			)
	move_and_slide()
	if (
		Input.is_action_just_pressed("Jump")
		and is_on_wall()
		and not is_on_floor()
	):
		var wall_normal: Vector2 = get_wall_normal()
		velocity.y = JUMP_VELOCITY
		velocity.x = wall_normal.x * WALL_REBOUND_SPEED
		wall_rebounding = true
		audio_stream_player.play()
