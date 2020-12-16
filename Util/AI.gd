extends Node

var ais = {}
var itempath = "res://Data/AI.json"
var noitem = 0
var idCount = noitem + 1

var nameToIdMap = {}

func _ready():
	var file = File.new()
	file.open(itempath, File.READ)
	ais = parse_json(file.get_as_text())
	file.close()
	# Set up all Item IDs
	for ai in ais["ai"]:
		ai["id"] = str(idCount)
		nameToIdMap[ai["name"]] = str(idCount)
		idCount += 1

func get_id_by_name(aiName:String) -> int :
	if nameToIdMap.has(aiName):
		return int(nameToIdMap[aiName])
	return -1

func get_name_by_id(id:int):
	return ais["ai"][id-1]["name"]

func get_entity_data(id:int):
	return ais["ai"][id-1]
