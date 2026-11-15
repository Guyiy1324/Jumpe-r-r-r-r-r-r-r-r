extends OptionButton

func _on_item_selected(index: int) -> void:
	if (index == 0):
		get_tree().quit()
