extends Node

# This is intend to be a function library for actions the player can do
const RenderClass = preload("res://Util/Render.gd")


func status(parameters: Dictionary)->void:
	var toggle = false
	var takes_turn = false
	var duration = 0
	var effect = PlayerState.effects.PHASE

	if parameters.has("toggle"):
		toggle = parameters["toggle"]
	if parameters.has("takes_turn"):
		takes_turn = parameters["takes_turn"]
	if parameters.has("effect_time"):
		duration = parameters["effect_time"]
	if parameters.has("effect"):
		match parameters["effect"]:
			"phase":
				effect = PlayerState.effects.PHASE
			"render":
				effect = PlayerState.effects.RENDER_ST
			"render_path":
				effect = PlayerState.effects.RENDER_PATH

	if toggle and PlayerState.is_effect(effect):
		PlayerState.set_duration(effect, 0)
	else:
		PlayerState.set_duration(effect, duration)
	if takes_turn:
		GameState.turn_elapsed()

func interact_door(parameters: Dictionary)->void:
	if GameState.player == null:
		return
	var state = false
	if parameters.has("state"):
		state = parameters["state"]
	if parameters.has("lock") and parameters["lock"]:
		for door in GameState.player.doors:
			if door.locked:
				door.unlock_door()
				#TODO key item consumption
				break
	else:
		for door in GameState.player.doors:
			if state:
				door.open_door()
			else:
				door.close_door()
	GameState.request_render(RenderClass.renderTarget.ACTIONS)

func gen(parameters: Dictionary)->void:
	if GameState.map == null:
		return
	GameState.map.call(parameters.get("algorithm"))
