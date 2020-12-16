extends StaticBody2D


var open = false
var locked = false
export(int) var open_frame = 141
export(int) var locked_frame = 156
export(int) var closed_frame = 140

func _ready():
	$TextureSprite.flip_h = bool(randi()%2)

func close_door():
	open = false
	$TextureSprite.frame = closed_frame
	$CollisionShape2D.disabled = false

func open_door():
	open = true
	$TextureSprite.frame = open_frame
	$CollisionShape2D.disabled = true

func lock_door():
	open = false
	locked = true
	$TextureSprite.frame = locked_frame
	$CollisionShape2D.disabled = false

func unlock_door():
	locked = false
	open_door()
	
