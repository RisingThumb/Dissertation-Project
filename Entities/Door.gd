extends StaticBody2D


var open = false
export(int) var open_frame = 141
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
