extends CharacterBody2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var ball_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ball_radius: float = (collision_shape.shape as CircleShape2D).radius * collision_shape.scale.x

const SPEED: float = 500.0
const ACCELERATION: float = 3500.0
const DECELERATION: float = 3000.0
const JUMP_VELOCITY: float = -600.0
const WALL_REBOUND_SPEED: float = 700.0
const WALL_INPUT_LOCK_TIME: float = 0.2
const WALL_REBOUND_DECELERATION: float = 1500.0

var wall_rebounding: bool = false
var wall_input_lock_remaining: float = 0.0
var wall_jump_normal_x: float = 0.0
var last_wall_jump_height: float = 0.0
var has_wall_jumped: bool = false


func _ready() -> void:
	ball_sprite.scale = Vector2.ONE * (ball_radius * 2.0 / ball_sprite.texture.get_width())


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		wall_rebounding = false
		wall_input_lock_remaining = 0.0
		has_wall_jumped = false
		velocity.y = JUMP_VELOCITY
		audio_stream_player.play()

	var direction: float = Input.get_axis("ui_left", "ui_right")
	wall_input_lock_remaining = maxf(0.0, wall_input_lock_remaining - delta)
	if (wall_input_lock_remaining > 0.0 or (has_wall_jumped and velocity.y < 0.0)) and direction * wall_jump_normal_x < 0.0:
		direction = 0.0

	if wall_rebounding:
		if direction != 0.0:
			wall_rebounding = false
		else:
			velocity.x = move_toward(velocity.x, 0.0, WALL_REBOUND_DECELERATION * delta)
			if is_zero_approx(velocity.x):
				wall_rebounding = false
	if not wall_rebounding:
		var acceleration: float = ACCELERATION if direction != 0.0 else DECELERATION
		velocity.x = move_toward(velocity.x, direction * SPEED, acceleration * delta)
	move_and_slide()
	ball_sprite.rotate(get_position_delta().x / ball_radius)

	if Input.is_action_just_pressed("Jump") and is_on_wall() and not is_on_floor():
		var wall_normal: Vector2 = get_wall_normal()
		var same_wall_side: bool = has_wall_jumped and wall_normal.x * wall_jump_normal_x > 0.0
		if not same_wall_side or global_position.y >= last_wall_jump_height:
			wall_jump_normal_x = wall_normal.x
			last_wall_jump_height = global_position.y
			has_wall_jumped = true
			wall_input_lock_remaining = WALL_INPUT_LOCK_TIME
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_REBOUND_SPEED
			wall_rebounding = true
			audio_stream_player.play()

@export var jump_velocity: float = 400.0

func bounce(bounce_velocity: float = jump_velocity * 3.0) -> void:
	wall_rebounding = false
	wall_input_lock_remaining = 0.0
	has_wall_jumped = false
	velocity.y = -bounce_velocity
