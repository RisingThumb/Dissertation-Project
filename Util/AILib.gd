extends Node

const EntityClass = preload("res://Entities/Entity.gd")

# All actions an AI can perform go here

func move_random(AIRef: EntityClass):
	var move = Vector2(0,0)
	var move_dir = randf()
	if move_dir < 0.25:
		move = Vector2.LEFT
	elif move_dir < 0.5:
		move = Vector2.RIGHT
	elif move_dir < 0.75:
		move = Vector2.UP
	else:
		move = Vector2.DOWN
	AIRef.move(move)

func move_to_player(AIRef: EntityClass):
	pass

func idle(AIRef: EntityClass):
	pass # This is intended pass

func bite(AIRef: EntityClass):
	pass

func chess_knight(AIRef: EntityClass):
	var move=Vector2(1,2)
	var movePossibilities = []
	for i in [-1, 1]:
		for j in [-1, 1]:
			movePossibilities.append(Vector2(move.x*i, move.y*j))
			movePossibilities.append(Vector2(move.y*i, move.x*j))
	var possibleMoves = []
	for m in movePossibilities:
		var colls = AIRef.get_world_2d().direct_space_state.intersect_point(AIRef.trueposition+m*AIRef.get_parent().get_parent().tile_size + Vector2(1,1), 2)
		if colls.size() == 0:
			possibleMoves.append(m)
	possibleMoves.shuffle()
	if possibleMoves.size() != 0:
		AIRef.move(possibleMoves.pop_back())
	# No moves? Just idle
