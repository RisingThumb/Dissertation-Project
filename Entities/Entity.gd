extends StaticBody2D

var trueposition : Vector2
var sequenceUsed = "abaac"
var angrySequenceUsed = "abaac"
var aiBehaviours = {}
var aiAngryBehaviours = {}
var AIData = {}
var state = aiState.idle
var blind = false
var cooldownMax = 5
var cooldown = 0

enum aiState {
	angry,
	idle
}

var behaviourValue = randi()

func _ready():
	#GameState.connect("enemy_turn", self, "my_turn")
	pass

func player_next_to_me():
	var previousState = state
	state = aiState.angry
	cooldown = cooldownMax
	if previousState != state:
		$AnimationPlayer.play("StatusChanged")

func set_from_data(data: Dictionary):
	set_collision(data.get("collision"))
	set_texture(data.get("frame"))
	set_group(data.get("group"))
	set_behaviour_sequence(data.get("sequence"))
	set_behaviours(data.get("behaviours"))
	set_angry_behaviour_sequence(data.get("angrySequence"))
	set_angry_behaviours(data.get("angryBehaviours"))
	blind = data.get("blind")
	cooldownMax = data.get("stateCooldown")

func set_collision(col:bool):
	$CollisionShape2D.disabled = !col

func set_texture(sprite:int):
	$TextureSprite.frame = sprite

func set_behaviour_sequence(sequence:String):
	sequenceUsed = sequence
	behaviourValue = behaviourValue % sequenceUsed.length()

func set_angry_behaviour_sequence(sequence:String):
	angrySequenceUsed = sequence

func set_behaviours(behaviours: Dictionary):
	for behaviour in behaviours.keys():
		set_behaviour_char(behaviour, behaviours[behaviour])

func set_angry_behaviours(behaviours: Dictionary):
	for behaviour in behaviours.keys():
		set_angry_behaviour_char(behaviour, behaviours[behaviour])

func set_behaviour_char(behaviourCharacter: String, behaviourName:String):
	aiBehaviours[behaviourCharacter] = behaviourName

func set_angry_behaviour_char(behaviourCharacter: String, behaviourName:String):
	aiAngryBehaviours[behaviourCharacter] = behaviourName

func set_position(pos):
	trueposition = pos
	global_position = pos

func _process(delta):
	$CollisionShape2D.global_position = trueposition

func move(dir:Vector2):
	var colls = get_world_2d().direct_space_state.intersect_point(trueposition+dir*get_parent().get_parent().tile_size + Vector2(1,1), 2)
	if colls.size() == 0 and dir.length() > 0:
		trueposition += dir*16
		$Tween.interpolate_property(self, "global_position", global_position, trueposition, 0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		$Tween.start()

func set_group(groupName: String):
	self.add_to_group(groupName)

func can_i_see_you() -> bool:
	var previousState = state
	if GameState.player == null:
		return false
	if blind:
		if cooldown == 0:
			state = aiState.idle
	else:
		$RayCast2D.cast_to = GameState.player.global_position+Vector2(8,8)
		$RayCast2D.force_raycast_update()
		if $RayCast2D.get_collider() == GameState.player:
			state = aiState.angry
			cooldown = cooldownMax
		else:
			if cooldown == 0:
				state = aiState.idle
	if state != previousState:
		if $AnimationPlayer.is_playing():
			$AnimationPlayer.stop()
		$AnimationPlayer.play("StatusChanged")
	if state == aiState.angry:
		return true
	return false

func set_status_sprite():
	if state == aiState.angry:
		$StatusSprite.frame = 53
		$StatusSprite.modulate = Color.red
	if state == aiState.idle:
		$StatusSprite.frame = 48
		$StatusSprite.modulate = Color.yellow

func my_turn():
	behaviourValue+=1
	behaviourValue %= sequenceUsed.length()
	cooldown -= 1
	can_i_see_you()
	if state == aiState.idle:
		var action = sequenceUsed[behaviourValue]
		AiLib.call(aiBehaviours[action], self)
	elif state == aiState.angry:
		var action = angrySequenceUsed[behaviourValue]
		AiLib.call(aiAngryBehaviours[action], self)
