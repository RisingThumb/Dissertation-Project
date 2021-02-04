extends Node


func _ready():
	var _connected = GameState.connect("enemy_turn", self, "handle_entity_turns")

func handle_entity_turns():
	var entities = get_children()
	for entity in entities:
		yield(get_tree(),"idle_frame")
		if entity.has_method("my_turn"):
			entity.call("my_turn")
