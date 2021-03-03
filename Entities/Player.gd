extends StaticBody2D

const RenderClass = preload("res://Util/Render.gd")
const LightSpell = preload("res://Entities/LightSpell.tscn")

onready var atkAnim = $AttackAnims
onready var dist1 = $AroundAttacks/Distance1
onready var dist2 = $AroundAttacks/Distance2
onready var atkArea = $AroundAttacks


var missile = false
var input_dir : Vector2
var trueposition : Vector2
var areaCollisions : Dictionary = {
	"exit": false
}
var doors = []
onready var ownArea = $Area2D
var triggerActionRedrawThisFrame = 0
var take_turn = true

func _ready()->void:
	input_dir = Vector2(0, 0)
	trueposition = global_position
	GameState.player = self
	yield(get_tree(),"idle_frame")
	
	if GameState.map != null:
		set_camera_limit(GameState.map.bias.x*GameState.map.tile_size, GameState.map.bias.y*GameState.map.tile_size)
	PlayerState.player = self

func set_camera_limit(width:int, height:int):
	$Camera2D.limit_right = width
	$Camera2D.limit_bottom = height

func spell_zap():
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "enemy" in body.get_groups():
			body.call("hurt", 2)
			print("Hurting " + str(body) + " for 2 damage!")
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_stun():
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "enemy" in body.get_groups():
			body.call("stun")
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_teleport():
	var area = GameState.map.bias
	while true:
		var testPos = Vector2(floor(rand_range(1, area.x)), floor(rand_range(1, area.y)))
		print("Test pos is "+ str(testPos))
		if GameState.map.Map.get_cell_autotile_coord(testPos.x, testPos.y) == GameState.map.air_coord:
			set_position(testPos*GameState.tile_size)
			break

func spell_heal():
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "enemy" in body.get_groups():
			body.call("hurt", -2)
	PlayerState.change_hp(2)
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_speed():
	GameState.turns_remaining+=2
	GameState.turn_elapsed() # Hacky but this gets the menu updated

func spell_dig():
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "door" in body.get_groups():
			body.call("dig")
	var mapPos = trueposition/GameState.tile_size
	for i in [1, 0, -1]:
		for j in [1, 0, -1]:
			var gen = GameState.map
			var map = gen.Map
			gen.p_set_cell(map, mapPos.x + i, mapPos.y + j, gen.air_coord.x, gen.air_coord.y)
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_missile_up():
	spell_missile(Vector2.UP)

func spell_missile_down():
	spell_missile(Vector2.DOWN)

func spell_missile_left():
	spell_missile(Vector2.LEFT)

func spell_missile_right():
	spell_missile(Vector2.RIGHT)

func spell_missile(direction: Vector2):
	missile = true
	$RayCast2D.cast_to = GameState.tile_size * 11 * direction
	$RayCast2D.force_raycast_update()
	var c =$RayCast2D.get_collider()
	if c != null and "enemy" in c.get_groups():
		c.call("hurt", 3)
	yield(get_tree(), "idle_frame")
	$Line2D.default_color = Color.aqua
	GameState.turn_elapsed()
	$MissileTimer.start($MissileTimer.wait_time)

func spell_polymorph_up():
	spell_polymorph(Vector2.UP)

func spell_polymorph_down():
	spell_polymorph(Vector2.DOWN)

func spell_polymorph_left():
	spell_polymorph(Vector2.LEFT)

func spell_polymorph_right():
	spell_polymorph(Vector2.RIGHT)

func spell_polymorph(direction: Vector2):
	missile = true
	$RayCast2D.cast_to = GameState.tile_size * 5 * direction
	$RayCast2D.force_raycast_update()
	var c =$RayCast2D.get_collider()
	if c != null and "enemy" in c.get_groups():
		c.call("polymorph")
	yield(get_tree(), "idle_frame")
	$Line2D.default_color = Color.fuchsia
	GameState.turn_elapsed()
	$MissileTimer.start($MissileTimer.wait_time)

func spell_transform():# Quantum spell
	GameState.map.random_air()
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_light():
	$Light2D.texture_scale = 4.1
	GameState.turn_elapsed()

func spell_death():# The yellow sign
	PlayerState.current_max_sanity -= 1
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "enemy" in body.get_groups():
			body.call("hurt", 10000) # 10,000 damage is reasonable... right?
			print("Hurting " + str(body) + " for lots of damage!")
	yield(get_tree(), "idle_frame")
	GameState.turn_elapsed()

func spell_open():
	dist1.disabled = false
	dist2.disabled = true
	var bodies = atkArea.get_overlapping_bodies()
	for body in bodies:
		if "door" in body.get_groups():
			body.call("unlock_door")
	GameState.turn_elapsed()

func hurt(damage):
	PlayerState.current_hp -= 1
	GameState.request_render(RenderClass.renderTarget.STATUS)

func on_exit() -> bool:
	return areaCollisions["exit"]

func set_position(pos:Vector2):
	trueposition = pos
	global_position = pos

func _process(_delta)->void:
	ownArea.global_position = trueposition
	$CollisionShape2D.global_position = trueposition + Vector2(8,8)
	process_input()
	if GameState.turns_remaining != 0:
		process_movement()
	triggerActionRedrawThisFrame = 0
	#if missile:
	$Line2D.visible = missile
	if missile: # Magic Missile effect
		var iter = 0
		var increment = $RayCast2D.cast_to / $Line2D.points.size()
		for point in $Line2D.points:
			$Line2D.points[iter] = increment*iter
			if iter != 0 and iter != $Line2D.points.size():
				if increment.x!= 0:
					$Line2D.points[iter].y = rand_range(-10, 10)
				if increment.y!= 0:
					$Line2D.points[iter].x = rand_range(-10, 10)
			iter+=1
	

func process_input()->void:
	input_dir.x = int(Input.is_action_just_pressed("right")) - \
				int(Input.is_action_just_pressed("left"))
	input_dir.y = int(Input.is_action_just_pressed("down")) - \
				int(Input.is_action_just_pressed("up"))
	if Input.is_action_just_pressed("nothing"):
		GameState.turn_elapsed()
		GameState.request_render(RenderClass.renderTarget.ACTIONS)

func process_movement()->void:
	var colls = get_world_2d().direct_space_state.intersect_point(trueposition+input_dir*get_parent().tile_size + Vector2(4,4), 2) # Vector2(4, 4) is in case it's not an exact bounding box
	# perform movement
	if (colls.size() == 0 or PlayerState.is_effect(PlayerState.effects.PHASE)) and input_dir.length() > 0:
		trueposition += input_dir*16
		$Tween.interpolate_property(self, "global_position", global_position, trueposition, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		GameState.turn_elapsed()
		GameState.request_render(RenderClass.renderTarget.ACTIONS)
	if input_dir.length() > 0 and colls.size() > 0 and "entity" in colls[0]["collider"].get_groups():
		if colls[0]["collider"].has_method("hurt"):
			colls[0]["collider"].hurt(PlayerState.current_damage)
		atkAnim.stop(true)
		match input_dir:
			Vector2.UP:
				atkAnim.play("atk_up")
			Vector2.DOWN:
				atkAnim.play("atk_down")
			Vector2.LEFT:
				atkAnim.play("atk_left")
			Vector2.RIGHT:
				atkAnim.play("atk_right")
		GameState.turn_elapsed()


func _on_Area2D_area_entered(area):
	if "exit" in area.get_parent().get_groups():
		areaCollisions["exit"] = true
	if "door" in area.get_parent().get_groups():
		doors.append(area.get_parent())
	if "enemy" in area.get_parent().get_groups():
		area.get_parent().player_next_to_me()
	if !triggerActionRedrawThisFrame:
		triggerActionRedrawThisFrame += 1
		for i in triggerActionRedrawThisFrame:
			yield(get_tree(),"idle_frame")
		GameState.request_render(RenderClass.renderTarget.ACTIONS)

func _on_Area2D_area_exited(area):
	if "exit" in area.get_parent().get_groups():
		areaCollisions["exit"] = false
	if "door" in area.get_parent().get_groups():
		for i in range(doors.size()):
			if doors[i] == area.get_parent():
				doors.remove(i)
				break
	if !triggerActionRedrawThisFrame:
		triggerActionRedrawThisFrame += 1
		for i in triggerActionRedrawThisFrame:
			yield(get_tree(),"idle_frame")
		GameState.request_render(RenderClass.renderTarget.ACTIONS)


func _on_MissileTimer_timeout():
	missile = false
	pass # Replace with function body.
