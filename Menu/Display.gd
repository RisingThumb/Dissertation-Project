extends TextureRect

onready var Renderer = $"../Viewport/Sprite"

func _ready():
	pass

func _input(event: InputEvent):
	if not event is InputEventMouse:
		return

	if not Renderer:
		print("Could not mount renderer")
		return
