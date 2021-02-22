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
	var bestMove = Vector2(0, 0)
	if GameState.player == null:
		return
	var closestDist = -1
	var possibleMoves = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for move in possibleMoves:
		if closestDist == -1:
			closestDist = (AIRef.trueposition + move*GameState.tile_size).distance_to(GameState.player.trueposition)
			bestMove = move
			continue
		if (AIRef.trueposition + move*GameState.tile_size).distance_to(GameState.player.trueposition) < closestDist:
			closestDist = (AIRef.trueposition + move*GameState.tile_size).distance_to(GameState.player.trueposition)
			bestMove = move
	AIRef.move(bestMove)

func idle(AIRef: EntityClass):
	pass # This is intended pass

func bite(AIRef: EntityClass):
	var p = PlayerState.get_player()
	if p == null:
		return move_to_player(AIRef)
	var dir = (p.trueposition - AIRef.trueposition)/GameState.tile_size
	match dir:
		Vector2.UP:
			AIRef.atkAnim.play("atk_up")
		Vector2.DOWN:
			AIRef.atkAnim.play("atk_down")
		Vector2.LEFT:
			AIRef.atkAnim.play("atk_left")
		Vector2.RIGHT:
			AIRef.atkAnim.play("atk_right")
	if p.trueposition.distance_to(AIRef.trueposition) < GameState.tile_size+4:
		if p.has_method("hurt"):
			p.hurt(AIRef.damage)

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
