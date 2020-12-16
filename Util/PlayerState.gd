extends Node

# Handles specific information with regards to the player
const RenderClass = preload("res://Util/Render.gd")
const MAX_HP : int = 12
const MAX_STAMINA : int = 7
const MAX_SANITY : int = 8
var current_hp : int
var current_stamina : int
var current_sanity : int

const INVENTORY_SIZE : int = 20
var inventory:Array = []

enum effects {
	PHASE = 0,
	RENDER_ST,
	RENDER_PATH,
	EFFECT_NUMBER
}

# Index is effect name, Value is effect duration
var status_effects = []

func is_effect(effect: int)-> bool:
	return status_effects[effect] != 0

# Below should be removed...
func is_phasing()-> bool:
	return status_effects[effects.PHASE] != 0

func get_effect_name(effect: int)-> String:
	var text = ""
	match effect:
		effects.PHASE:
			text="Phasing"
		effects.RENDER_ST:
			text="Rendering Spanning Tree"
		effects.RENDER_PATH:
			text="Rendering Path"
	return text

func get_duration(effect: int)-> int:
	return status_effects[effect]

func set_duration(effect: int, duration: int)-> void:
	status_effects[effect] = duration

func _ready():
	current_hp = MAX_HP
	current_sanity = MAX_SANITY
	current_stamina = MAX_STAMINA
	inventory.append(Item.get_item_by_name("Demonicron"))
	inventory.append(Item.get_item_by_name("Book of Terrain"))
	for _i in range(effects.EFFECT_NUMBER):
		status_effects.append(0)

func change_hp(amount : int) -> void:
	current_hp += amount
	if current_hp > MAX_HP:
		current_hp = MAX_HP
	GameState.request_render(RenderClass.renderTarget.STATUS)

func change_stamina(amount : int) -> void:
	current_stamina += amount
	if current_stamina > MAX_STAMINA:
		current_stamina = MAX_STAMINA
	GameState.request_render(RenderClass.renderTarget.STATUS)

func change_sanity(amount : int) -> void:
	current_sanity += amount
	if current_sanity > MAX_SANITY:
		current_sanity = MAX_SANITY
	GameState.request_render(RenderClass.renderTarget.STATUS)

func get_hp() -> int:
	return current_hp

func get_stamina() -> int:
	return current_stamina

func get_sanity() -> int:
	return current_sanity
