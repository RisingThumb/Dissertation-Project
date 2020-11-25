extends Node

var elapsed : int
var turns_remaining : int
var start_turns = 3
const RenderClass = preload("res://Util/Render.gd")
const GeneratorClass = preload("res://Entities/Generator.gd")
const PlayerClass = preload("res://Entities/Player.gd")
var render: RenderClass = null
var map: GeneratorClass = null
var player: PlayerClass = null
signal enemy_turn

func _ready() -> void:
	elapsed = 0
	turns_remaining = start_turns

# Seriously, Clean this up later!
func get_extra_actions() -> Array:
	var actions: Array = []
	if player == null:
		return actions
	if player.on_exit():
		var new_action = {
			"name":"Delve Deeper",
			"function":"gen",
			"parameters":{
				"algorithm":"set_level_data"
			}
		}
		actions.append(new_action)
	var closedAdded = false
	var openAdded = false
	for door in player.doors:
		if !door.open and !openAdded:
			var new_action = {
			"name":"Open Door",
			"function":"interact_door",
			"parameters":{
				"state":true
				}
			}
			actions.append(new_action)
			openAdded = true

		if door.open and !closedAdded:
			var new_action = {
			"name":"Close Door",
			"function":"interact_door",
			"parameters":{
				"state":false
				}
			}
			actions.append(new_action)
			closedAdded = true
		if closedAdded and openAdded:
			break
	return actions

func turn_elapsed()->void:
	turns_remaining -= 1
	elapsed += 1
	if turns_remaining == 0:
		emit_signal("enemy_turn")
		turns_remaining = start_turns
	request_render(RenderClass.renderTarget.TURNS)

func request_render(renderTarget:int)->void:
	if render != null:
		render.redraw(renderTarget)

func get_elapsed() -> int:
	return elapsed

func get_turns_remaining() -> int:
	return turns_remaining

func show_actions_for_item(id:int) -> void:
	if render != null:
		render.draw_actions(id)

func request_effects():
	if render != null:
		render.redraw(RenderClass.renderTarget.EFFECTS)
