extends Node


func _ready():
	GameState.connect("enemy_turn", self, "handle_entity_turns")

func handle_entity_turns():
	var entities = get_children()
	for entity in entities:
		if entity.has_method("my_turn"):
			entity.call("my_turn")
