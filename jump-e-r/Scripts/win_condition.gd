extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	var burger = get_tree().get_first_node_in_group("hamburger")

	if burger == null:
		print("Hamburger was not found.")
		return

	if burger.is_in_player_possession:
		print("The burger is in the player's possession.")
		get_tree().change_scene_to_file("res://Scenes/cutscene.tscn")
	else:
		print("The burger is not in the player's possession.")
