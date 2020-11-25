extends Node

var items = {}
var itempath = "res://Data/Items.json"
var noitem = 0
var idCount = noitem + 1

var nameToIdMap = {}

func _ready():
	var file = File.new()
	file.open(itempath, File.READ)
	items = parse_json(file.get_as_text())
	file.close()
	# Set up all Item IDs
	for item in items["items"]:
		item["id"] = str(idCount)
		nameToIdMap[item["name"]] = str(idCount)
		idCount += 1

func get_item_by_name(itemName:String) -> int :
	if nameToIdMap.has(itemName):
		return int(nameToIdMap[itemName])
	return -1

func get_name_by_id(id:int):
	return items["items"][id-1]["name"]

func get_functions_by_id(id:int)->Array:
	if id <0 or id >= idCount:
		return []
	return items["items"][id-1]["functions"]
