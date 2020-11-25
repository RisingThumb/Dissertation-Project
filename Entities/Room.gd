extends Node2D

var x :int
var y :int
var width :int
var height :int

# based on http://kidscancode.org/blog/2018/12/godot3_procgen6/
func make_room(pos, size) -> void:
	x = int(pos.x)
	y = int(pos.y)
	width = int(size.x)
	height = int(size.y)

func value_out_range(value, max_value, min_value) -> bool:
	return (value <= min_value) and (value >= max_value)

func overlaps(rect2) -> bool:
	var xOverlap = 	value_out_range(x, rect2.x, rect2.x + rect2.width) or \
					value_out_range(rect2.x, x, x + width)
	var yOverlap = 	value_out_range(y, rect2.y, rect2.y + rect2.height) or \
					value_out_range(rect2.y, y, y + height)
	return xOverlap and yOverlap
