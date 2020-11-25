extends Button

#const RenderClass = preload("res://Util/Render.gd")
var function_name: String
var parameters: Dictionary

func set_function(function: String, params:Dictionary)->void:
	function_name = function
	parameters = params

func _on_Action_pressed():
	Lib.call(function_name, parameters)
	if parameters.has("render_effect") and parameters["render_effect"]:
		GameState.request_effects()
