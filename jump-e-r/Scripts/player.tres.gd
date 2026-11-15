extends CharacterBody2D


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var ball_sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var ball_radius: float = (
	(collision_shape.shape as CircleShape2D).radius
	* collision_shape.scale.x
)


const SPEED: float = 500.0
const ACCELERATION: float = 3500.0
const DECELERATION: float = 3000.0
const JUMP_VELOCITY: float = -600.0

const WALL_REBOUND_SPEED: float = 700.0
const WALL_INPUT_LOCK_TIME: float = 0.2
const WALL_REBOUND_DECELERATION: float = 1500.0
const MAX_WALL_SLIDE_SPEED: float = 180.0

# Allows Jump to be pressed slightly before wall contact.
const JUMP_BUFFER_TIME: float = 0.12

# The player must fall below the previous wall-jump height
# before jumping from that same wall again.
const SAME_WALL_DROP_DISTANCE: float = 8.0


@export var jump_velocity: float = 400.0


var wall_rebounding: bool = false
var wall_input_lock_remaining: float = 0.0
var wall_jump_normal_x: float = 0.0

var jump_buffer_remaining: float = 0.0
var is_dead: bool = false

# Same-wall neutral-jump prevention.
var has_wall_jumped: bool = false
var previous_wall_normal_x: float = 0.0
var previous_wall_jump_y: float = 0.0
var same_wall_jump_unlocked: bool = false


func _ready() -> void:
	# Prevent vertical walls from being classified as floors by
	# CharacterBody2D's built-in floor detection.
	floor_max_angle = deg_to_rad(45.0)

	ball_sprite.scale = Vector2.ONE * (
		ball_radius * 2.0 / ball_sprite.texture.get_width()
	)


func _physics_process(delta: float) -> void:
	_update_jump_buffer(delta)

	var standing_on_real_floor: bool = _is_real_floor()

	# Apply gravity unless standing on a genuine upward-facing floor.
	# This ensures the player falls while touching a wall.
	if not standing_on_real_floor:
		velocity += get_gravity() * delta

	# Automatic bounce only happens on a real floor.
	if standing_on_real_floor:
		wall_rebounding = false
		wall_input_lock_remaining = 0.0

		_reset_wall_jump_restriction()

		velocity.y = JUMP_VELOCITY
		audio_stream_player.play()


	var direction: float = Input.get_axis("ui_left", "ui_right")

	wall_input_lock_remaining = maxf(
		wall_input_lock_remaining - delta,
		0.0
	)


	# Prevent steering back into the wall immediately after a wall jump.
	if (
		wall_input_lock_remaining > 0.0
		and direction * wall_jump_normal_x < 0.0
	):
		direction = 0.0


	if wall_rebounding:
		if direction != 0.0:
			wall_rebounding = false
		else:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				WALL_REBOUND_DECELERATION * delta
			)

			if is_zero_approx(velocity.x):
				wall_rebounding = false


	if not wall_rebounding:
		var acceleration: float = (
			ACCELERATION if direction != 0.0 else DECELERATION
		)

		velocity.x = move_toward(
			velocity.x,
			direction * SPEED,
			acceleration * delta
		)


	move_and_slide()

	ball_sprite.rotate(get_position_delta().x / ball_radius)


	# Wall sliding.
	#
	# Positive velocity.y means falling. This limits falling speed without
	# stopping gravity. Negative velocity.y is preserved for wall jumps.
	if is_on_wall() and not _is_real_floor():
		velocity.y = minf(
			velocity.y,
			MAX_WALL_SLIDE_SPEED
		)


	# A same-wall jump becomes available only after the player has
	# actually fallen below the previous jump height.
	if (
		has_wall_jumped
		and velocity.y > 0.0
		and global_position.y
			>= previous_wall_jump_y + SAME_WALL_DROP_DISTANCE
	):
		same_wall_jump_unlocked = true


	_try_wall_jump()


func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_remaining = JUMP_BUFFER_TIME
	else:
		jump_buffer_remaining = maxf(
			jump_buffer_remaining - delta,
			0.0
		)


func _try_wall_jump() -> void:
	if jump_buffer_remaining <= 0.0:
		return

	if not is_on_wall():
		return

	if _is_real_floor():
		return

	var wall_normal: Vector2 = get_wall_normal()
	var current_wall_side: float = signf(wall_normal.x)

	if is_zero_approx(current_wall_side):
		return


	var touching_same_wall: bool = (
		has_wall_jumped
		and is_equal_approx(
			current_wall_side,
			previous_wall_normal_x
		)
	)


	# First wall jump: allowed immediately.
	# Opposite wall: allowed immediately.
	# Same wall: allowed only after falling below the previous
	# wall-jump height.
	var can_wall_jump: bool = (
		not has_wall_jumped
		or not touching_same_wall
		or same_wall_jump_unlocked
	)


	if not can_wall_jump:
		# Consume the input so holding Jump cannot repeatedly
		# trigger a neutral wall jump.
		jump_buffer_remaining = 0.0
		return


	jump_buffer_remaining = 0.0

	wall_jump_normal_x = current_wall_side

	previous_wall_normal_x = current_wall_side
	previous_wall_jump_y = global_position.y

	has_wall_jumped = true
	same_wall_jump_unlocked = false

	wall_input_lock_remaining = WALL_INPUT_LOCK_TIME

	velocity.y = JUMP_VELOCITY
	velocity.x = current_wall_side * WALL_REBOUND_SPEED
	wall_rebounding = true

	audio_stream_player.play()


func _is_real_floor() -> bool:
	if not is_on_floor():
		return false

	# A real floor points upward. A vertical wall points sideways.
	return get_floor_normal().dot(Vector2.UP) >= 0.7


func _reset_wall_jump_restriction() -> void:
	has_wall_jumped = false
	previous_wall_normal_x = 0.0
	previous_wall_jump_y = 0.0
	same_wall_jump_unlocked = false


func bounce(
	bounce_velocity: float = jump_velocity * 3.0
) -> void:
	if is_dead:
		return

	wall_rebounding = false
	wall_input_lock_remaining = 0.0
	wall_jump_normal_x = 0.0
	jump_buffer_remaining = 0.0

	_reset_wall_jump_restriction()

	velocity.y = -bounce_velocity


func die(respawn_position: Vector2) -> void:
	if is_dead:
		return

	is_dead = true
	set_physics_process(false)

	velocity = Vector2.ZERO

	ball_sprite.hide()
	collision_shape.set_deferred("disabled", true)

	audio_stream_player.stop()

	# death_sound.play()
	death_particles.restart()

	await get_tree().create_timer(2.0).timeout

	global_position = respawn_position

	await get_tree().physics_frame
	await get_tree().physics_frame

	wall_rebounding = false
	wall_input_lock_remaining = 0.0
	wall_jump_normal_x = 0.0
	jump_buffer_remaining = 0.0

	_reset_wall_jump_restriction()

	ball_sprite.rotation = 0.0
	ball_sprite.show()

	collision_shape.set_deferred("disabled", false)

	is_dead = false
	set_physics_process(true)
