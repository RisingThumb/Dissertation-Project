extends Button

var id : int

func set_item_id(itemId: int) -> void:
	self.id = itemId

func _on_Item_pressed():
	GameState.show_actions_for_item(self.id)
