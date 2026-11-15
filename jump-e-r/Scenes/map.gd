extends Node2D

var hamburger_scene = preload("res://Scenes/hamburgoer.tscn")
var receiver_scene = preload("res://Scenes/win_condition.tscn")


func _ready() -> void:
	var hamburger = hamburger_scene.instantiate()
	hamburger.name = "Hamburger"
	add_child(hamburger)

	var receiver = receiver_scene.instantiate()
	receiver.name = "Receiver"
	add_child(receiver)

	hide_items_attached_to_player()


func hide_items_attached_to_player() -> void:
	var player := get_node_or_null("Player")

	if player == null:
		print("Player node was not found.")
		return

	for child in player.get_children():
		if child.name == "Hamburgoer" or child.name == "WinCondition":
			child.hide()
			disable_collisions(child)
			print("Hidden duplicate: ", child.name)


func disable_collisions(node: Node) -> void:
	if node is CollisionObject2D:
		node.process_mode = Node.PROCESS_MODE_DISABLED

	for child in node.get_children():
		disable_collisions(child)
