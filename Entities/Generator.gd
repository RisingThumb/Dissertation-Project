extends Node2D

const RenderClass = preload("res://Util/Render.gd")
const PlayerClass = preload("res://Entities/Player.tscn")

onready var RoomContainer = $Rooms
onready var Map = $TileMap
onready var EntityContainer = $Entities

export(int,0, 1000) var room_attempts = 100
export(int, 1) var min_size = 4
export(int, 1) var max_size = 10
export(Vector2) var bias = Vector2(61, 31)
var Room = preload("res://Entities/Room.tscn")
var Exit = preload("res://Entities/Stairs.tscn")
var Door = preload("res://Entities/Door.tscn")
var Entity = preload("res://Entities/Entity.tscn")
var ItemEnt = preload("res://Entities/Item.tscn")
var itempoint = 0

var enemies = []

var tile_size = 16
var room_generating = true
var cull = 0.7
var air_sets = []

var wall_coords = [Vector2(0, 8), Vector2(1, 8), Vector2(2, 8), Vector2(3, 8), Vector2(4, 8), Vector2(5, 8)]
var air_coord = Vector2(7,9)
var maze_coord = Vector2(1,12)
var cave_coord = Vector2(5,6)

var show_bounding_box = false
var show_spanning_tree = true
var renderst = []
var chosen_path = []

enum maze_info {
	NONE = 0,
	UP = 1,
	DOWN = 2,
	LEFT = 4,
	RIGHT = 8
}

func _ready():
	set_level_data()
	GameState.map = self
	randomize()

func fill_rooms():
	# First we pick a room as the room the player "Starts" at
	make_start_to_end_path()
	if chosen_path.size() == 0:
		print("err..?")
		var exit = Exit.instance()
		EntityContainer.add_child(exit)
		var things = [exit, GameState.player]
		var area = GameState.map.bias
		for thing in things:
			while true:
				var testPos = Vector2(floor(rand_range(1, area.x)), floor(rand_range(1, area.y)))
				if GameState.map.Map.get_cell_autotile_coord(testPos.x, testPos.y) == GameState.map.air_coord:
					if thing == GameState.player:
						GameState.player.set_position(testPos*GameState.tile_size)
					else:
						thing.global_position = testPos*GameState.tile_size
					break
	else:
		var startRoom = RoomContainer.get_children()[chosen_path[0]]
		var endRoom = RoomContainer.get_children()[chosen_path[-1]]
		if GameState.player != null and startRoom != null:
			GameState.player.set_position(Vector2(
				(startRoom.x+1+((startRoom.width-1)/2))*tile_size,
				(startRoom.y+1+((startRoom.height-1)/2))*tile_size
			))
		if endRoom != null:
			var new_ent = Exit.instance()
			new_ent.global_position = Vector2(
				(endRoom.x+1+((endRoom.width-1)/2))*tile_size,
				(endRoom.y+1+((endRoom.height-1)/2))*tile_size
			)
			EntityContainer.add_child(new_ent)

func populate_world(rooms:bool=false) -> void:
	if !rooms:
		# Enemies
		for x in range(1, bias.x):
			for y in range(1, bias.y):
				if Map.get_cell_autotile_coord(x, y) == air_coord: # TODO add check for door/player
					for enemy in enemies:
						randomize()
						if randf() < enemy.get("probability"):
							var entityId = Ai.get_id_by_name(enemy.get("name"))
							var entityData = Ai.get_entity_data(entityId)
							var newEntity = Entity.instance()
							newEntity.set_from_data(entityData)
							newEntity.set_position(Vector2(x*tile_size, y*tile_size))
							EntityContainer.add_child(newEntity)
							break
		# Items
		for i in range(itempoint):
			while true:
				var testPos = Vector2(floor(rand_range(1, bias.x)), floor(rand_range(1, bias.y)))
				if Map.get_cell_autotile_coord(testPos.x, testPos.y) == air_coord:
					var itemEnt = ItemEnt.instance()
					EntityContainer.add_child(itemEnt)
					itemEnt.global_position = testPos*tile_size
					randomize()
					var check = randf()
					if check < 0.25: # key
						itemEnt.set_item(itemEnt.Item.KEY)
					elif check < 0.3: # Meat
						itemEnt.set_item(itemEnt.Item.MEAT)
					elif check < 0.4: # Bread
						itemEnt.set_item(itemEnt.Item.BREAD)
					elif check < 0.5:
						itemEnt.set_item(itemEnt.Item.FRUIT)
					elif check < 0.67:
						itemEnt.set_item(itemEnt.Item.EYES)
					elif check < 0.77:
						itemEnt.set_item(itemEnt.Item.CANDY)
					elif check < 0.85:
						itemEnt.set_item(itemEnt.Item.POTION_MINOR)
					elif check < 0.95:
						itemEnt.set_item(itemEnt.Item.POTION_MAJOR)
					print("Placed item!")
					break

func make_start_to_end_path():
	if RoomContainer.get_child_count() == 0:
		return
	# We have a new spanning tree to look at
	var newst:Array = renderst.duplicate()
	newst.shuffle()
	var startEdge = newst.pop_back()
	var roomsInPath: Array = []
	var current = startEdge[0];
	var first = true
	var continue_at_other_end = false
	var other_point = null
	while(!(current in roomsInPath)):
		roomsInPath.append(current)
		var possible_connections: Array = []
		for edge in renderst:
			if edge[0] == current:
				if !(edge[1] in roomsInPath):
					possible_connections.append(edge[1])
			if edge[1] == current:
				if !(edge[0] in roomsInPath):
					possible_connections.append(edge[0])
		if possible_connections.size() == 0:
			if continue_at_other_end:
				roomsInPath.invert()
				current = other_point
				continue_at_other_end = false
				continue
			break
		possible_connections.shuffle()
		if first and possible_connections.size() >= 2:
			continue_at_other_end = true
			first = false
			other_point = possible_connections.pop_back()
		if first:
			first = false
		current = possible_connections.pop_back()

	chosen_path = roomsInPath

func set_level_data():
	if GameState.render != null:
		GameState.render.present_choices(true)
	randomize()
	chosen_path = []
	var data: Dictionary = Level.next_level()
	enemies = data.get("enemies")
	for entity in EntityContainer.get_children():
		entity.queue_free()
	Map.modulate = Color(str(data.get("fg1")))
	itempoint = data.get("item_points")
	var functions: Array = data.get("function_order")
	prepare_tiles()
	for function in functions:
		self.call(function)
	GameState.request_render(RenderClass.renderTarget.ROOM_TITLE)

func uncarve(times:int = 100):
	while times > 0:
		for x in range(1, bias.x):
			for y in range(1, bias.y):
				if Map.get_cell_autotile_coord(x, y) == maze_coord:
					# Test if it should be uncarved
					var count = 0
					for x_change in range(-1, 2, 2):
						if Map.get_cell_autotile_coord(x+x_change, y) in wall_coords:
							count+=1
					for y_change in range(-1, 2, 2):
						if Map.get_cell_autotile_coord(x, y+y_change) in wall_coords:
							count+=1
					if count >= 3:
						p_set_cell(Map, x, y, randi() % 3, 8)
		times -= 1

func random_air():
	for x in range(4, bias.x-3):
		for y in range(4, bias.y-3):
			if randf() < 0.5:
				p_set_cell(Map, x, y, air_coord.x, air_coord.y)

# Functions flood_fill and dig_caves based on below tutorial
# https://abitawake.com/news/articles/procedural-generation-with-godot-creating-caves-with-cellular-automata
func dig_caves(iterations:int = 23000, neighbours:int = 4):
	for _i in range(iterations):
		var x = floor(rand_range(1, bias.x-1))
		var y = floor(rand_range(1, bias.y-1))
		if check_nearby(x, y) > neighbours:
			p_set_cell(Map, x, y, 3+randi()%3, 8)
		elif check_nearby(x, y) < neighbours:
			p_set_cell(Map, x, y, air_coord.x, air_coord.y)

func get_air_sets():
	air_sets = []
	
	for x in range(0, bias.x):
		for y in range(0, bias.y):
			if Map.get_cell_autotile_coord(x, y) == air_coord:
				flood_fill(x,y)

	for set in air_sets:
		for tile in set:
			p_set_cell(Map, tile.x, tile.y, air_coord.x, air_coord.y)

func flood_fill(x:int, y:int):
	var set = []
	var filling = [Vector2(x, y)]
	while filling:
		var tile = filling.pop_back()
		
		if !set.has(tile):
			set.append(tile)
			p_set_cell(Map, tile.x, tile.y, cave_coord.x, cave_coord.y)
			var extraDirs = [tile+Vector2.UP, tile+Vector2.DOWN, tile+Vector2.LEFT, tile+Vector2.RIGHT]
			
			for dir in extraDirs:
				if Map.get_cell_autotile_coord(dir.x, dir.y) == air_coord:
					if !filling.has(dir) and !set.has(dir):
						filling.append(dir)

	air_sets.append(set)

func connect_air_sets():
	if air_sets.size() == 1:
		return
	var prev_set = null
	var tunnel_sets = air_sets.duplicate()
	for set in tunnel_sets:
		if prev_set:
			var new_point = set[randi() % set.size()]
			var prev_point = prev_set[randi() % prev_set.size()]
			
			if new_point != prev_point:
				drunken_corridor(prev_point, new_point, set)
		prev_set = set

func drunken_corridor(point1, point2, set):
	var max_steps = 1000
	var steps = 0
	var drunk_x = point1.x
	var drunk_y = point1.y
	while steps < max_steps and !Vector2(drunk_x, drunk_y) in set:
		steps+=1
		# Directional weightings
		var n = 1.0
		var s = 1.0
		var e = 1.0
		var w = 1.0
		var weight = 1.0
		
		if drunk_x < point2.x: # Left of point
			e += weight
		if drunk_x > point2.x:
			w+=weight
		if drunk_y < point2.y:
			s+=weight
		if drunk_y > point2.y:
			n+=weight
		var total = n+s+e+w
		#normalize all weightings
		n /= total
		s /= total
		e /= total
		w /= total
		
		var dx
		var dy
		
		var choice = randf()
		
		if 0 <= choice and choice < n:
			dx = 0
			dy = -1
		elif n <= choice and choice < (n+s):
			dx = 0
			dy = 1
		elif (n + s) <= choice and choice < (n+s+e):
			dx = 1
			dy = 0
		else:
			dx = -1
			dy = 0
		if (2 < drunk_x + dx and drunk_x + dx < bias.x-2) and \
			(2 < drunk_y + dy and drunk_y + dy < bias.y-2):
			drunk_x += dx
			drunk_y += dy
			if Map.get_cell_autotile_coord(drunk_x, drunk_y) in wall_coords:
				p_set_cell(Map, drunk_x, drunk_y, air_coord.x, air_coord.y)
				p_set_cell(Map, drunk_x+1, drunk_y, air_coord.x, air_coord.y)
				p_set_cell(Map, drunk_x+1, drunk_y+1, air_coord.x, air_coord.y)
	p_set_cell(Map, drunk_x, drunk_y, air_coord.x, air_coord.y)

func check_nearby(x:int, y:int) -> int:
	var count = 0
	if Map.get_cell_autotile_coord(x+1, y-1) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x+1, y) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x+1, y+1) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x, y-1) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x, y+1) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x-1, y-1) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x-1, y) in wall_coords: count+=1
	if Map.get_cell_autotile_coord(x-1, y+1) in wall_coords: count+=1
	return count

func clear_maze_tiles():
	for x in range(1, bias.x):
		for y in range(1, bias.y):
			if Map.get_cell_autotile_coord(x, y) == maze_coord:
				p_set_cell(Map, x, y, air_coord.x, air_coord.y)

func replace_decor():
	for x in range(1, bias.x):
		for y in range(1, bias.y):
			if Map.get_cell_autotile_coord(x, y) == air_coord and randf() < 0.03:
				p_set_cell(Map, x, y, randi() % 3, 12)
				
func recursive_backtrack_maze():
	var matrix = []
	var maze_width = int(bias.x/2) # truncates
	var maze_height = int(bias.y/2)
	# Prefill the maze matrix
	for x in range(maze_width):
		matrix.append([])
		for _y in range(maze_height+1):
			matrix[x].append(maze_info.NONE)
	var stack = []
	var visited = []
	# We search the map for a valid place to start generating the maze
	stack.append(Vector2(0, 0))
	visited.append(Vector2(0, 0))
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	while stack.size() > 0:
		var current_coord = stack[stack.size()-1]
		var choices = []
		for dir in directions:
			var possible_dir = dir+current_coord
			if !(possible_dir in visited) and \
				possible_dir.x >= 0 and possible_dir.x < maze_width and \
				possible_dir.y >= 0 and possible_dir.y < maze_height:
				choices.append(dir)
		if choices.size() == 0: # Backtrack, all spaces visited
			stack.pop_back()
			continue
		var choice_made = randi() % choices.size()
		if choices[choice_made] == Vector2.UP:
			matrix[current_coord.x][current_coord.y] += maze_info.UP
		if choices[choice_made] == Vector2.DOWN:
			matrix[current_coord.x][current_coord.y] += maze_info.DOWN
		if choices[choice_made] == Vector2.LEFT:
			matrix[current_coord.x][current_coord.y] += maze_info.LEFT
		if choices[choice_made] == Vector2.RIGHT:
			matrix[current_coord.x][current_coord.y] += maze_info.RIGHT
		visited.append(current_coord+choices[choice_made])
		stack.append(current_coord+choices[choice_made])
	# Maze generated in matrix. Now we convert the matrix into tilemap equivalent
	for x in range(maze_width):
		for y in range(maze_height):
			p_set_cell(Map, x*2+1, y*2+1, maze_coord.x, maze_coord.y)
			if matrix[x][y] & maze_info.RIGHT:
				p_set_cell(Map, x*2+2, y*2+1, maze_coord.x, maze_coord.y)
			if matrix[x][y] & maze_info.LEFT:
				p_set_cell(Map, x*2, y*2+1, maze_coord.x, maze_coord.y)
			if matrix[x][y] & maze_info.DOWN:
				p_set_cell(Map, x*2+1, y*2+2, maze_coord.x, maze_coord.y)
			if matrix[x][y] & maze_info.UP:
				p_set_cell(Map, x*2+1, y*2, maze_coord.x, maze_coord.y)

# Here we generate a spanning tree from our rooms
func generate_st() -> Array:
	var rooms = RoomContainer.get_children()
	#pregenerate a complete graph which we will iterate through
	var complete_graph = []
	for indexA in range(rooms.size()-1):
		for indexB in range(indexA+1, rooms.size()):
			if indexA == indexB:
				continue
			var pos1 = Vector2(rooms[indexA].x + rooms[indexA].width/2, rooms[indexA].y + rooms[indexA].height/2)
			var pos2 = Vector2(rooms[indexB].x + rooms[indexB].width/2, rooms[indexB].y + rooms[indexB].height/2)
			complete_graph.append([indexA, indexB, int(pos1.distance_to(pos2))])
	var visited = []
	var st = []
	visited.append(0)
	var max_int = 9223372036854775807
	for _i in range(rooms.size()):
		var currentChoice = [0, 0, max_int] # This is maximum integer
		var indexToRemove = -1
		for point in visited:
			var indexToTrack = -1
			for edge in complete_graph:
				indexToTrack += 1
				if edge[0] == point or edge[1] == point:
					if currentChoice[2] > edge[2] and \
						(!(edge[0] in visited) or !(edge[1] in visited)):
						currentChoice = edge
						indexToRemove = indexToTrack
		if indexToRemove >= 0 and indexToRemove < complete_graph.size():
			complete_graph.remove(indexToRemove)
		if currentChoice[0] in visited:
			visited.append(currentChoice[1])
		else:
			visited.append(currentChoice[0])
		st.append([currentChoice[0], currentChoice[1]])
	return st


func make_corridors(door_probability:int = 1.0): # Type not used but should be used at some point for corrdor variation
	for arc in renderst:
		var room1 = RoomContainer.get_child(arc[0])
		var room2 = RoomContainer.get_child(arc[1])
		var horizdist = abs(room1.x - room2.x)
		var vertdist = abs(room1.y - room2.y)
		var corridorpositions = []
		if horizdist > vertdist: # We make them on the left and right edges of room
			var pos1 = Vector2(0, (randi()%(room1.height-2))+1+room1.y)
			var pos2 = Vector2(0, (randi()%(room2.height-2))+1+room2.y)
			if room1.x < room2.x-1: # Room1 is to the left
				pos1.x = room1.width+room1.x-2
				pos2.x = room2.x + 0
			else: # Room2 is to the left
				pos1.x = room1.x +0
				pos2.x = room2.width+room2.x-1
			corridorpositions.append(pos1)
			corridorpositions.append(pos2)
		else: # We make them on the top and bottom edges of the room
			var pos1 = Vector2((randi()%(room1.width-2))+1+room1.x, 0)
			var pos2 = Vector2((randi()%(room2.width-2))+1+room2.x, 0)
			if room1.y < room2.y: # Room1 is above
				pos1.y = room1.y + room1.height -1
				pos2.y = room2.y +0
			else: # Room2 is above
				pos1.y = room1.y +0
				pos2.y = room2.y + room2.height -1
			corridorpositions.append(pos1)
			corridorpositions.append(pos2)
		# We have the 2 chosen positions, now we make a corridor
		corridorpositions.shuffle()
		# Iterate towards it
		p_set_cell(Map, corridorpositions[0].x, corridorpositions[0].y, air_coord.x, air_coord.y)
		var exit = false
		while corridorpositions[0].x < corridorpositions[1].x:
			corridorpositions[0].x+=1
			p_set_cell(Map, corridorpositions[0].x, corridorpositions[0].y, air_coord.x, air_coord.y)
			if corridorpositions[0].x == corridorpositions[1].x and \
				Map.get_cell_autotile_coord(corridorpositions[0].x+1, corridorpositions[0].y) == air_coord:
					if !exit:
						make_doors(door_probability, corridorpositions[0], arc[1], arc[0])
						exit = true
		while corridorpositions[0].x > corridorpositions[1].x:
			corridorpositions[0].x-=1
			p_set_cell(Map, corridorpositions[0].x, corridorpositions[0].y, air_coord.x, air_coord.y)
			if corridorpositions[0].x == corridorpositions[1].x and \
				Map.get_cell_autotile_coord(corridorpositions[0].x-1, corridorpositions[0].y) == air_coord:
					if !exit:
						make_doors(door_probability, corridorpositions[0], arc[1], arc[0])
						exit = true
		while corridorpositions[0].y < corridorpositions[1].y:
			corridorpositions[0].y+=1
			p_set_cell(Map, corridorpositions[0].x, corridorpositions[0].y, air_coord.x, air_coord.y)
			if Map.get_cell_autotile_coord(corridorpositions[0].x+1, corridorpositions[0].y) == air_coord or \
				Map.get_cell_autotile_coord(corridorpositions[0].x-1, corridorpositions[0].y) == air_coord:
				if !exit:
					exit = true
					make_doors(door_probability, corridorpositions[0], arc[1], arc[0])
		while corridorpositions[0].y > corridorpositions[1].y:
			corridorpositions[0].y-=1
			p_set_cell(Map, corridorpositions[0].x, corridorpositions[0].y, air_coord.x, air_coord.y)
			if Map.get_cell_autotile_coord(corridorpositions[0].x+1, corridorpositions[0].y) == air_coord or \
				Map.get_cell_autotile_coord(corridorpositions[0].x-1, corridorpositions[0].y) == air_coord:
				if !exit:
					exit = true
					make_doors(door_probability, corridorpositions[0], arc[1], arc[0])

func prepare_tiles():
	renderst.clear()
	chosen_path.clear()
	for ent in EntityContainer.get_children():
		ent.queue_free()
	var children = RoomContainer.get_children()
	for room in children:
		RoomContainer.remove_child(room)
		room.queue_free()
	Map.clear()
	fill_map()

func generate_rooms():
	for _i in room_attempts:
		var room = Room.instance()
		var pos = Vector2(round(rand_range(1, bias.x-max_size-1)), round(rand_range(1, bias.y-max_size-1)))
		var size = Vector2(round(rand_range(min_size, max_size-1)), round(rand_range(min_size, max_size-1)))
		if int(pos.x) % 2 == 1:
			pos.x += 1
		if int(pos.y) % 2 == 1:
			pos.y += 1
		if int(size.x) % 2 == 0:
			size.x += 1
		if int(size.y) % 2 == 0:
			size.y += 1
		room.make_room(pos, size)
		var success = true
		for room2 in RoomContainer.get_children():
			if room.overlaps(room2):
				room.queue_free()
				success = false
				break
		if !success:
			continue
		RoomContainer.add_child(room)
	make_rooms()
	renderst = generate_st()


func fill_map():
	for x in range(bias.x):
		for y in range(bias.y):
			p_set_cell(Map, x, y, 3 + (randi() % 3), 8)

func make_rooms():
	for room in RoomContainer.get_children():
		for x in range(1, room.width-1):
			for y in range(1, room.height-1):
				p_set_cell(Map, x+room.x, y+room.y, air_coord.x, air_coord.y)
		for x in range(0, room.width):
			p_set_cell(Map, x+room.x, room.y, randi() % 3, 8)
			p_set_cell(Map, x+room.x, room.y+room.height-1, randi() % 3, 8)
		for y in range(0, room.height):
			p_set_cell(Map, room.x, room.y+y, randi() % 3, 8)
			p_set_cell(Map, room.x+room.width-1, room.y+y, randi() % 3, 8)

func make_doors(probability: float, pos: Vector2, roomNo: int, otherRoomNo:int):
	if randf() < probability:
		probability -= randf()*0.2
		var new_door = Door.instance()
		new_door.global_position = pos*tile_size
		if !(roomNo in chosen_path) and !(otherRoomNo in chosen_path) and randf() < probability:
			new_door.lock_door()
		EntityContainer.add_child(new_door)
	

func p_set_cell(map, x, y, xid, yid):
	map.set_cell(x, y, 0, false, false, false, Vector2(xid, yid))

func _draw():
	if PlayerState.is_effect(PlayerState.effects.RENDER_ST):
		for room in RoomContainer.get_children():
			draw_circle(Vector2((room.x + room.width/2) * tile_size + 8, 
								(room.y + room.height/2) * tile_size),
								4, Color(32, 228, 0))
			for edge in renderst:
				var r1 = RoomContainer.get_child(edge[0])
				var r2 = RoomContainer.get_child(edge[1])
				var pos1 = Vector2((r1.x+r1.width/2)*tile_size + 8, (r1.y+r1.height/2)*tile_size)
				var pos2 = Vector2((r2.x+r2.width/2)*tile_size + 8, (r2.y+r2.height/2)*tile_size)
				draw_line(pos1, pos2, Color(32, 228, 0), 0.5)
	if PlayerState.is_effect(PlayerState.effects.RENDER_PATH):
		var room = null
		var prevroom = null
		for node in chosen_path:
			prevroom = room
			room = RoomContainer.get_child(node)
			draw_circle(Vector2((room.x + room.width/2) * tile_size + 8, 
								(room.y + room.height/2) * tile_size),
								4, Color(32, 228, 0))
			if prevroom != null:
				var pos1 = Vector2((room.x+room.width/2)*tile_size + 8, (room.y+room.height/2)*tile_size)
				var pos2 = Vector2((prevroom.x+prevroom.width/2)*tile_size + 8, (prevroom.y+prevroom.height/2)*tile_size)
				draw_line(pos1, pos2, Color(32, 228, 0), 0.5)

func _process(_delta):
	update()
