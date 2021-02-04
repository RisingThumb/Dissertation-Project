extends StaticBody2D

const RenderClass = preload("res://Util/Render.gd")

onready var atkAnim = $AttackAnims

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
