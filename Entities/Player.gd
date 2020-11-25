extends Node2D

const RenderClass = preload("res://Util/Render.gd")

var input_dir : Vector2
var trueposition : Vector2
var areaCollisions : Dictionary = {
	"exit": false
}
var doors = []

func _ready()->void:
	input_dir = Vector2(0, 0)
	trueposition = global_position
	GameState.player = self
	yield(get_tree(),"idle_frame")
	set_camera_limit(GameState.map.bias.x*GameState.map.tile_size, GameState.map.bias.y*GameState.map.tile_size)

func set_camera_limit(width:int, height:int):
	$Camera2D.limit_right = width
	$Camera2D.limit_bottom = height

func on_exit() -> bool:
	return areaCollisions["exit"]

func set_position(pos:Vector2):
	trueposition = pos
	global_position = pos

func _process(_delta)->void:
	process_input()
	process_movement()

func process_input()->void:
	input_dir.x = int(Input.is_action_just_pressed("right")) - \
				int(Input.is_action_just_pressed("left"))
	input_dir.y = int(Input.is_action_just_pressed("down")) - \
				int(Input.is_action_just_pressed("up"))

func process_movement()->void:
	var colls = get_world_2d().direct_space_state.intersect_point(trueposition+input_dir*get_parent().tile_size + Vector2(1,1), 2)
	# perform movement
	if (colls.size() == 0 or PlayerState.is_effect(PlayerState.effects.PHASE)) and input_dir.length() > 0:
		trueposition += input_dir*16
		$Tween.interpolate_property(self, "global_position", global_position, trueposition, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()
		GameState.turn_elapsed()


func _on_Area2D_area_entered(area):
	if "exit" in area.get_parent().get_groups():
		areaCollisions["exit"] = true
	if "door" in area.get_parent().get_groups():
		doors.append(area.get_parent())
	GameState.request_render(RenderClass.renderTarget.ACTIONS)

func _on_Area2D_area_exited(area):
	if "exit" in area.get_parent().get_groups():
		areaCollisions["exit"] = false
	if "door" in area.get_parent().get_groups():
		for i in range(doors.size()):
			if doors[i] == area.get_parent():
				doors.remove(i)
				break
	GameState.request_render(RenderClass.renderTarget.ACTIONS)
