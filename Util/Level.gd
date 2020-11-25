extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var levelspath = "res://Data/Levels.json"
var currentLevel:int = -1
var levels: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var file = File.new()
	file.open(levelspath, File.READ)
	levels = parse_json(file.get_as_text())
	file.close()

func get_level(level: int) -> Dictionary:
	var l:Array = levels.get("levels")
	if level < 0 or level >= l.size():
		return levels.get("default") # Error case
	return levels.get("levels")[level]

func next_level() -> Dictionary:
	currentLevel += 1
	return get_current_level()

func get_current_level() -> Dictionary:
	return get_level(currentLevel)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
