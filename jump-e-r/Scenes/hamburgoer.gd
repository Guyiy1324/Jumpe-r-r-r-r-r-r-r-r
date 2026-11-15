extends Area2D

@export var distance_behind: float = 100.0

var player: CharacterBody2D
var last_direction: float = 1.0
var is_in_player_possession: bool = false


func _ready() -> void:
	add_to_group("hamburger")


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player = body
		is_in_player_possession = true
		print("Hamburger picked up.")


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	if player.velocity.x != 0:
		last_direction = sign(player.velocity.x)

	global_position = player.global_position - Vector2(
		last_direction * distance_behind,
		0
	)
