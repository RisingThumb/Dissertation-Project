extends Node2D

var LSystems:Dictionary = {}

func _ready():
	add_L_System("A",
		{
			"A":"ABA",
			"B":"BBB"
		},
		[],
		"cantor"
	)
	generate_iterations("cantor", 5)
	print(LSystems["cantor"]["iterations"])

func add_L_System(axiom:String, rules:Dictionary, iterations:Array, id:String):
	LSystems[id] = {
		"axiom": axiom,
		"rules": rules,
		"iterations": iterations
	}

func generate_iterations(LSystemName:String, n:int) -> void:
	if !LSystems.has(LSystemName):
		return
	var sys = LSystems[LSystemName]
	sys["iterations"].clear()
	sys["iterations"].append(sys["axiom"])
	for i in range(1, n+1):
		iterations.append(generate_iteration(i))

func generate_iteration(n:int) -> String:
	var previous_iter = iterations[n-1]
	var new_iter:String
	for c in previous_iter:
		if rules.has(c):
			new_iter += rules[c]
	return new_iter
